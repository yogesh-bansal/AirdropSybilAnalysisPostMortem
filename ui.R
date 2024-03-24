## Loading Libraries
library(shiny)
library(bslib)
library(networkD3)
library(DT)
library(shinycssloaders)
library(shinydashboard)
library(ggplot2)
library(hrbrthemes)

## UI
addResourcePath("images", "images")
ui <- fluidPage(theme = bs_theme(bootswatch = "sandstone"),
  br(),
  fluidRow(
    column(width = 6,tags$a(target = "_blank", href="https://thankarb.com/", tags$img(src = "images/AF_lockup_navy.png", height="80px")),align="left"),
    column(width = 6,tags$a(target = "_blank", href="https://app.dework.xyz/datagrants-thankar", tags$img(src = "images/odc.png", height="100px")),align="right"),
  ),
  tabsetPanel(
    tabPanel("Airdrop Receiver Participation Over Time",
     fluidRow(
      column(width = 7,withSpinner(plotOutput("votes_gdf"))),
      column(width = 5,withSpinner(plotOutput("vote_timesdf_hourly")))
      ),
     fluidRow(
      column(width = 7,withSpinner(plotOutput("users_newlong"))),
      column(width = 5,withSpinner(plotOutput("vote_timesdf_weekly")))
      )
    ),
    tabPanel("Airdrop Receiver Sybil Analysis Post-Mortem",
      br(),
      sidebarLayout(
        sidebarPanel(width=3,
          sliderInput("score_cutoff", label = "Similarity Score Cutoff", min = .75, max = 1, value = .99,step=.01),
          br(),
          sliderInput("min_comprop", label = "Minimum Common Proposals Voted on", min = 10, max = 109, value = 100,step=1)
        ),
        mainPanel(width=9,
          withSpinner(forceNetworkOutput("coll_network",height="800px"))
        )
      )
    ),
    tabPanel("Airdrop Receiver DNA Data",
      br(),
      fluidPage(
          downloadButton("downloadData", "Download"),
          withSpinner(dataTableOutput("coll_data"))
          
      )
    ),
  )
)