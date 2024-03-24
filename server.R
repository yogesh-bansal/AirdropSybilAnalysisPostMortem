## Loading Libraries
library(shiny)
library(networkD3)
library(DT)
library(readr)
library(ggplot2)
library(hrbrthemes)

########################################################################
## Load All data
########################################################################
## One time
# voter_score_dfAll <- readRDS("data/voter_score_df.RDS")
# voter_score_dfAll <- voter_score_dfAll[(duplicated(apply(voter_score_dfAll[,1:2],1,function(x) paste0(sort(x),collapse="")))),]
# saveRDS(voter_score_dfAll,"data/voter_score_df.RDS")
del_data <- readRDS("data/delegatesdf.RDS")
voter_score_dfAll <- readRDS("data/voter_score_df.RDS")
airdf <- readr::read_csv("data/airdrop.csv")
names(airdf) <- c("Address","Amount")

## read Plot data
votes_gdf <- readRDS("data/votes_gdf.RDS")
users_newlong <- readRDS("data/users_newlong.RDS")
vote_timesdf_hourly <- readRDS("data/vote_timesdf_hourly.RDS")
vote_timesdf_weekly <- readRDS("data/vote_timesdf_weekly.RDS")

########################################################################
## Server Code
########################################################################
function(input, output, session) {

	## Network Plot
    output$coll_network <- renderForceNetwork({
                                                voter_score_df <- voter_score_dfAll[voter_score_dfAll$Score>=input$score_cutoff & voter_score_dfAll$NumCommonVotedProposals>input$min_comprop,]
                                                if(nrow(voter_score_df)==0) return(NULL)
												## Prepare Nodes and Links
                                                all_voters <- unique(c(voter_score_df$voterA,voter_score_df$voterB))
												all_votersNames <- del_data$Name[match(all_voters,del_data$Address)]
												voter_nodes <- data.frame(
																			name=ifelse((all_votersNames=="")|is.na(all_votersNames),all_voters,all_votersNames),
																			group=c("<1000 ARB","1000 to 5000 ARB",">5000 ARB")[findInterval(airdf$Amount[match(tolower(all_voters),tolower(airdf$Address))],c(0,1000,5000))],
																			size=1
																)
												voter_links <- data.frame(
																			source = match(voter_score_df$voterAName,voter_nodes$name)-1,
																			target = match(voter_score_df$voterBName,voter_nodes$name)-1,
																			value=voter_score_df$Score
																)
												my_color <- 'd3.scaleOrdinal() .domain(["<1000 ARB", "1000 to 5000 ARB",">5000 ARB"]) .range(["#9DCCED","#12AAFF","#213147"])'
												forceNetwork(
													Links = voter_links,
													Nodes = voter_nodes,
													Source = "source", 
													Target = "target",
													Value = "value", 
													NodeID = "name",
													Nodesize = "size",
													Group = "group",
													legend=TRUE,
													colourScale=my_color,
													opacity = 1,
													fontSize = 12,
													opacityNoHover = 0,
													bounded=TRUE,
													zoom = FALSE
												)

                            })

    ## Data Table
    output$coll_data <- renderDataTable({
                                            outdata <- voter_score_dfAll[,c(5,6,4,3)]
                                            outdata$Score <- round(outdata$Score,2)
                                            names(outdata) <- c("AirdropReceiverA","AirdropReceiverB","CommonProposals","SimilarityScore")
                                            outdata <- outdata[order(-outdata$SimilarityScore,-outdata$CommonProposals),]
                                            datatable(
                                                        outdata,
                                                        escape = FALSE,
                                                        rownames=FALSE,
                                                        options = list(
                                                                        paging = TRUE,
                                                                        bInfo = FALSE,
                                                                        ordering=TRUE,
                                                                        searching=TRUE,
                                                                        autoWidth = TRUE,
                                                                        bLengthChange = FALSE,
                                                                        pageLength = 20
                                                                    )
                                                    )
                            })

    output$downloadData <- downloadHandler(
    filename = function() {
      # Use the selected dataset as the suggested file name
      "AirdropEngageDNA.csv"
    },
    content = function(file) {
      # Write the dataset to the `file` that will be downloaded
      outdata <- voter_score_dfAll[,c(5,6,4,3)]
	  outdata$Score <- round(outdata$Score,2)
	  names(outdata) <- c("AirdropReceiverA","AirdropReceiverB","CommonProposals","SimilarityScore")
	  outdata <- outdata[order(-outdata$SimilarityScore,-outdata$CommonProposals),]
      write_csv(outdata, file)
    }
  )

  output$votes_gdf <- renderPlot({
  									p2 <- ggplot(votes_gdf, aes(x=DateTime, y=Votes,group=Platform,color=Platform)) +
									geom_line() + 
									theme_ipsum() +
									xlab("")+
									ylab("Number of Votes")+
									ggtitle("Airdrop Receiver Votes on proposals over Time") +
									ylim(0,40000)
									p2
						})
  output$users_newlong <- renderPlot({
  									p3 <- ggplot(users_newlong, aes(x=DateTime, y=Users, fill=Type)) + 
									geom_area(alpha=0.6 , size=.5, colour="white") +
									theme_ipsum() + 
									xlab("")+
									ylab("Number of Voters")+
									ggtitle("Number of New Voters vs Existing Voters over Time (Out of Airdrop Receivers)")+
									facet_wrap(~Platform)
									p3
						})
    output$vote_timesdf_hourly <- renderPlot({
  									p7 <- ggplot(vote_timesdf_hourly, aes(x=Hour, y=Count,fill=Hour)) + 
							  		geom_bar(stat = "identity")+
							  		theme_ipsum() +
									xlab("")+
									ylab("Number of Votes")+
									ggtitle("Voting by time of the day") +
									ylim(0,120000)+
									theme(legend.position = "none")
									p7
						})
    output$vote_timesdf_weekly <- renderPlot({
  									p7 <- ggplot(vote_timesdf_weekly, aes(x=Weekday, y=Count, fill=Weekday)) + 
							  		geom_bar(stat = "identity")+
							  		theme_ipsum() +
									xlab("")+
									ylab("Number of Votes")+
									ggtitle("Voting by Weekday") +
									ylim(0,350000) +
									theme(legend.position = "none")
									p7
						})

}