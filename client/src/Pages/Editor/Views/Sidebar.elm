module Pages.Editor.Views.Sidebar exposing (..)

import Colors
import Css exposing (..)
import Ellie.Ui.Icon as Icon
import Ellie.Ui.Theme as Theme
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attributes exposing (css)


view : Html msg
view =
    Html.node "ellie-sidebar"
        [ css
            [ displayFlex
            , width (px 60)
            , backgroundColor Theme.primaryBackground
            , borderRight3 (px 2) solid Theme.staticBorder
            , flexDirection column
            , justifyContent spaceBetween
            , flexShrink (int 0)
            ]
        ]
        [ Html.div []
            [ viewLogo
            , viewIconButton Icon.Package
            , viewIconButton Icon.Settings
            , viewIconButton Icon.Help
            ]
        , Html.div []
            [ viewIconLink Icon.Slack "https://elmlang.slack.com/#ellie"
            , viewIconLink Icon.GithubProjects "https://github.com/lukewestby/ellie/projects"
            , viewIconLink Icon.GitHub "https://github.com/lukewestby/ellie"
            ]
        ]


viewLogo : Html msg
viewLogo =
    Html.div
        [ css
            [ width (px 58)
            , height (px 58)
            , padding4 (px 16) (px 16) (px 12) (px 16)
            , color Theme.primaryForeground
            ]
        ]
        [ Icon.view Icon.SmallLogo
        ]


viewIconButton : Icon.Icon -> Html msg
viewIconButton icon =
    Html.button
        [ css
            [ backgroundColor transparent
            , border zero
            , outline zero
            , padding2 (px 12) (px 16)
            , width (px 58)
            , height (px 50)
            , color Theme.primaryForeground
            , display block
            , cursor pointer
            ]
        ]
        [ Icon.view icon
        ]


viewIconLink : Icon.Icon -> String -> Html msg
viewIconLink icon url =
    Html.a
        [ Attributes.href url
        , Attributes.target "_blank"
        , css
            [ padding2 (px 12) (px 16)
            , width (px 58)
            , height (px 50)
            , color Theme.primaryForeground
            , display block
            , cursor pointer
            ]
        ]
        [ Icon.view icon
        ]
