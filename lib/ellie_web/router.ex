defmodule EllieWeb.Router do
  use EllieWeb, :router

  pipeline :browser do
    plug :accepts, ["html", "javascript"]
    plug :put_secure_browser_headers
    plug :put_layout, false
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug EllieWeb.Context
  end

  scope "/api" do
    pipe_through :api
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: EllieWeb.Schema
    forward "/", Absinthe.Plug, schema: EllieWeb.Schema
  end

  scope "/" do
    pipe_through :browser
    get "/private/result", EllieWeb.PageController, :result
    get "/a/terms/:version", EllieWeb.PageController, :terms
    get "/*path", EllieWeb.PageController, :new_editor
  end
end