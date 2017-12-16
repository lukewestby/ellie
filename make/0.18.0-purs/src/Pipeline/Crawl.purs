module Pipeline.Crawl where

import Ellie.Prelude
import BuildManager (Task)
import BuildManager as BM
import Control.Monad.Error.Class (throwError)
import Data.Array ((:))
import Data.Array.Extra as Array
import Data.Bifunctor (lmap)
import Data.Map (Map)
import Data.Map (lookup, mapWithKey) as Map
import Data.Map.Extra (mapKeys, toArray) as Map
import Data.Maybe (Maybe(..))
import Data.Newtype (unwrap)
import Data.Set (Set)
import Data.Set as Set
import Data.Traversable (traverse)
import Data.Url (Url)
import Elm.Compiler.Module.Name.Raw (Raw)
import Elm.Package (Package(..))
import Elm.Package as Package
import Elm.Package.Description (Description(..))
import Elm.Package.Description as Description
import Pipeline.Crawl.Package as CrawlPackage
import Pipeline.Install.Solver (Solution)
import System.FileSystem (FilePath)
import TheMasterPlan.CanonicalModule (CanonicalModule(..))
import TheMasterPlan.Location (Location(..))
import TheMasterPlan.Package (PackageGraph(..), PackageData(..))
import TheMasterPlan.Project (ProjectGraph(..), ProjectData(..))
import TheMasterPlan.Project as ProjectGraph


type ProjectInfo =
  { package :: Package
  , exposedModules :: Set CanonicalModule
  , allModules :: Array CanonicalModule
  , graph :: ProjectGraph Location
  }


crawl
  :: Url
  -> FilePath
  -> Description
  -> Solution
  -> Task ProjectInfo
crawl compilerUrl entry description@(Description d) solution = do
  depGraphs <-
    solution
      |> Map.toArray
      |> map Package.fromTuple
      |> traverse (crawlDependency compilerUrl entry solution)

  { moduleNames, packageGraph } <-
    CrawlPackage.dfsFromFiles compilerUrl "/" solution description [ entry ]

  let thisPackage = Package { name: d.name, version: d.version }
  let graph = canonicalizePackageGraph thisPackage packageGraph

  case Array.foldl1 ProjectGraph.union (graph : depGraphs) of
    Just projectGraph ->
      pure <|
        { package: thisPackage
        , graph: projectGraph
        , allModules:
            map
              ({ package: thisPackage, name: _ } >>> CanonicalModule)
              moduleNames
        , exposedModules:
            d.exposed
              |> map ({ package: thisPackage, name: _ } >>> CanonicalModule)
              |> Set.fromFoldable
        }

    Nothing ->
      throwError <|
        BM.PackageProblem "Somehow got an empty package graph. This should be impossible."


crawlDependency ::
  Url
  -> FilePath
  -> Solution
  -> Package
  -> Task (ProjectGraph Location)
crawlDependency compilerUrl entry solution package@(Package { name, version }) = do
  graphExists <- ProjectGraph.isSaved package
  if graphExists
    then
      ProjectGraph.load package
        |> lmap (unwrap >>> _.path >>> BM.CorruptedArtifact)
    else do
      description <-
        Description.load name version
          |> lmap (unwrap >>> _.path >>> BM.CorruptedArtifact)

      packageGraph <-
        CrawlPackage.dfsFromExposedModules compilerUrl "/" solution description

      let projectGraph = canonicalizePackageGraph package packageGraph

      ProjectGraph.save package projectGraph
        |> lmap (unwrap >>> _.path >>> BM.CorruptedArtifact)

      pure projectGraph


canonicalizePackageGraph :: Package -> PackageGraph -> ProjectGraph Location
canonicalizePackageGraph package packageGraph@(PackageGraph p) =
  let
    canonicalizeKeys :: ∀ a. Map Raw a -> Map CanonicalModule a
    canonicalizeKeys =
      Map.mapKeys ({ package, name: _ } >>> CanonicalModule)
  in
  ProjectGraph
    { data:
        Map.mapWithKey
          (\k v -> canonicalizePackageData package p.foreignDependencies v)
          (canonicalizeKeys p.data)
    , natives:
        Map.mapWithKey
          (\k v -> Location { package, relativePath: v })
          (canonicalizeKeys p.natives)
    }


canonicalizePackageData ::
    Package
    -> Map Raw Package
    -> PackageData
    -> ProjectData Location
canonicalizePackageData package foreignDependencies (PackageData { path, dependencies }) =
    let
        canonicalizeModule moduleName =
            case Map.lookup moduleName foreignDependencies of
                Nothing -> CanonicalModule { package, name: moduleName }
                Just foreignPackage -> CanonicalModule { package: foreignPackage, name: moduleName }
    in
    ProjectData
      { location: Location { relativePath: path, package }
      , dependencies: map canonicalizeModule dependencies
      }
