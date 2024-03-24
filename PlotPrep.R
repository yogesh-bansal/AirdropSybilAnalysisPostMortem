## Load Libraries
library(ggplot2)
library(lubridate)
library(hrbrthemes)
library(reshape2)

## Load Data
snap_props <- readRDS("../ArbSnapshotData/Proposals.RDS")
tally_props <- readRDS("../ArbTallyData/Proposals.RDS")
snap_votes <- readRDS("../ArbSnapshotData/Votes.RDS")
tally_votes <- readRDS("../ArbTallyData/Votes.RDS")
del_data <- readRDS("../ArbTallyData/delegatesdf.RDS")
del_list <- del_data$Address[del_data$delegatorsCount>1 & del_data$votesCount>10^18]
aird_list <- readr::read_csv("data/airdrop.csv")$`_recipients`

######################################################
## Plot 2
## Unique Voters over time
######################################################
## Snapshot
votes_gdf_sn <- data.frame(
							DateTime = as_datetime(snap_props$created),
							Platform = "Snapshot",
							Votes = sapply(snap_props$id,function(x,tdata,del_list) sum(tolower(unique(tdata$voter[tdata$prop_id==x])) %in% tolower(del_list)),tdata=snap_votes,del_list=aird_list)
				)
votes_gdf_tal <- data.frame(
							DateTime = as_datetime(tally_props$block),
							Platform = "Tally",
							Votes = sapply(tally_props$id,function(x,tdata,del_list) sum(tolower(unique(tdata$voter[tdata$id==x])) %in% tolower(del_list)),tdata=tally_votes,del_list=aird_list)
				)
votes_gdf_tal <- votes_gdf_tal[order(votes_gdf_tal$DateTime),]
votes_gdf <- rbind(votes_gdf_sn,votes_gdf_tal)
rownames(votes_gdf) <- NULL
saveRDS(votes_gdf,"data/votes_gdf.RDS")
######################################################
######################################################


######################################################
## Plot 3
## New Users over time
######################################################
## Snapshot
snap_prop_chron <- snap_props[order(snap_props$created),c("created","id")]
users_new_sn <- data.frame(
							DateTime = as_datetime(snap_prop_chron$created),
							Proposal = snap_prop_chron$id,
							Platform = "Snapshot",
							PastUsers = NA,
							NewUsers = NA
				)
users_old <- character()
for(idx in 1:nrow(users_new_sn))
{
	cprop <- users_new_sn$Proposal[idx]
	cusers <- unique(snap_votes$voter[snap_votes$prop_id==cprop])
	cdusers <- cusers[tolower(cusers) %in% tolower(aird_list)]
	users_new_sn$PastUsers[idx] <- sum(cdusers%in%users_old)
	users_new_sn$NewUsers[idx] <- length(cdusers) - users_new_sn$PastUsers[idx]
	users_old <- unique(c(users_old,cdusers))
	message(idx)
}

## Tally
tally_prop_chron <- tally_props[order(as_datetime(tally_props$block)),c("block","id")]
users_new_tal <- data.frame(
							DateTime = as_datetime(tally_prop_chron$block),
							Proposal = tally_prop_chron$id,
							Platform = "Tally",
							PastUsers = NA,
							NewUsers = NA
				)
users_old <- character()
for(idx in 1:nrow(users_new_tal))
{
	cprop <- users_new_tal$Proposal[idx]
	cusers <- unique(tally_votes$voter[tally_votes$id==cprop])
	cdusers <- cusers[tolower(cusers) %in% tolower(aird_list)]
	users_new_tal$PastUsers[idx] <- sum(cdusers%in%users_old)
	users_new_tal$NewUsers[idx] <- length(cdusers) - users_new_tal$PastUsers[idx]
	users_old <- unique(c(users_old,cdusers))
	message(idx)
}
users_new <- rbind(users_new_sn,users_new_tal)
users_newlong <- rbind(
						cbind(users_new[,1:3],Type="Previous Airdrop Receiver",Users=users_new$PastUsers),
						cbind(users_new[,1:3],Type="New Airdrop Receiver",Users=users_new$NewUsers)
					)
saveRDS(users_newlong,"data/users_newlong.RDS")
######################################################
######################################################


######################################################
## Plot 7
## Votes over time
######################################################
vote_times <- c(format(as_datetime(snap_votes$created[tolower(snap_votes$voter) %in% tolower(aird_list)]),"%H"),format(as_datetime(tally_votes$block[tolower(tally_votes$voter) %in% tolower(aird_list)]),"%H"))
vote_timesdf_hourly <- data.frame(Hour=names(table(vote_times)),Count=as.numeric(table(vote_times)))
saveRDS(vote_timesdf_hourly,"data/vote_timesdf_hourly.RDS")

vote_times <- c(format(as_datetime(snap_votes$created[tolower(snap_votes$voter) %in% tolower(aird_list)]),"%A"),format(as_datetime(tally_votes$block[tolower(tally_votes$voter) %in% tolower(aird_list)]),"%A"))
vote_timesdf_weekly <- data.frame(Weekday=names(table(vote_times)),Count=as.numeric(table(vote_times)))
vote_timesdf_weekly$Weekday <- factor(vote_timesdf_weekly$Weekday,levels=weekdays(Sys.Date()+1:7))
saveRDS(vote_timesdf_weekly,"data/vote_timesdf_weekly.RDS")
######################################################
######################################################