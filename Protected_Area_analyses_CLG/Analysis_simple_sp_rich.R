rm(list=ls()) 

library(yarg)
library(roquefort)
library(gamm4)


setwd("R:/ecocon_d/clg32/GitHub/PREDICTS_WDPA")
source("compare_randoms.R")
source("model_select.R")
setwd("R:/ecocon_d/clg32/PREDICTS/WDPA analysis")
PA_11_14 <- read.csv("PREDICTS_WDPA.csv")
multiple.taxa.matched.landuse <- subset(PA_11_14, multiple_taxa == "yes")


### model species richness

# check polynomials for confounding variables
fF <- c("Within_PA") 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")

Species_richness.best.random <- compare_randoms(multiple.taxa.PA_11_14, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

Species_richness.best.random$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"


sp.model <- model_select(all.data  = multiple.taxa.PA_11_14, 
			     responseVar = "Species_richness", 
			     fitFamily = "poisson", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = Species_richness.best.random$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
sp.model$final.call
sp.model$stats
# Species_richness~poly(ag_suit,1)+poly(log_elevation,1)+Within_PA+(Within_PA|SS)+(1|SSB)+(1|SSBS)

data = sp.model$data

m1 <- glmer(Species_richness ~ Within_PA + poly(log_elevation,1) + ag_suit
	+ (Within_PA|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = data)


# plot

labels <- c("Unprotected", "Protected")
y <- as.numeric(fixef(m1)[2])
se <- as.numeric(se.fixef(m1)[2])
yplus <- y + se*1.96
yminus <- y - se*1.96
y <-(exp(y)*100)
yplus<-(exp(yplus)*100)
yminus<-(exp(yminus)*100)

points <- c(100, y)
CI <- c(yplus, yminus)

plot(points ~ c(1,2), ylim = c(80,150), xlim = c(0.5,2.5), 
	bty = "l", pch = 16, col = c(1,3), cex = 1.5,
	yaxt = "n", xaxt = "n",
	ylab = "Species richness difference (% � 95%CI)",
	xlab = "")


text(2,80, paste("n =", length(data$SS[which(data$Within_PA == "yes")]), sep = " "))
text(1,80, paste("n =", length(data$SS[which(data$Within_PA == "no")]), sep = " "))


axis(1, c(1,2), labels)
axis(2, c(80,100,120,140), c(80,100,120,140))
arrows(2,CI[1],2,CI[2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2), pch = 16, col = c(1,3), cex = 1.5)



#keep points for master plot
sp.plot1 <- data.frame(label = c("unprotected", "all protected"), est = points, 
		upper = c(100, CI[1]), lower = c(100,CI[2]),
		n.site = c(length(data$SS[which(data$Within_PA == "no")]), length(data$SS[which(data$Within_PA == "yes")])))



### simple species richness with IUCN cat 

multiple.taxa.PA_11_14$IUCN_CAT <- relevel(multiple.taxa.PA_11_14$IUCN_CAT, "0")

# check polynomials for confounding variables
fF <- c("IUCN_CAT") 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("IUCN_CAT")


Species_richness.best.random.IUCN <- compare_randoms(multiple.taxa.PA_11_14, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

Species_richness.best.random.IUCN$best.random # "(1+IUCN_CAT|SS)+ (1|SSBS)+ (1|SSB)"


sp.model.IUCN <- model_select(all.data  = multiple.taxa.PA_11_14, 
			     responseVar = "Species_richness", 
			     fitFamily = "poisson", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = Species_richness.best.random.IUCN$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
sp.model.IUCN$stats
sp.model.IUCN$final.call
sp.model.IUCN$warnings

# "Species_richness~IUCN_CAT+poly(ag_suit,1)+poly(log_elevation,3)+(IUCN_CAT|SS)+(1|SSB)+(1|SSBS)"
# but, doesnt converge for elevation down to quadratic

# compare cubic and linear models manually to see if it makes a difference

m3ii <- glmer(Species_richness ~ IUCN_CAT + poly(log_elevation,3) + ag_suit
	+ (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = sp.model.IUCN$data)
m3i <- glmer(Species_richness ~ IUCN_CAT  + poly(log_elevation,1) + ag_suit
	+ (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = sp.model.IUCN$data)
anova(m3ii, m3i) # borderline, not sig difference
fixef(m3ii)
fixef(m3i)
#coefficients are similar for both models, i.e. form of relationship with elevation not critical so use stats table as above 

#double check elevation does need to be in the model
m3iii <- glmer(Species_richness ~ IUCN_CAT  + poly(log_elevation,1) + ag_suit
	+ (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = sp.model.IUCN$data)
m3iv <- glmer(Species_richness ~ IUCN_CAT  + ag_suit
	+ (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = sp.model.IUCN$data)
anova(m3iii, m3iv)

#use stats table

# plot 


labels <- c("Unprotected", "III  - VI", "unknown",  "I & II" )

data <- sp.model.IUCN$data
data$IUCN_CAT <- relevel(data$IUCN_CAT, "0")

m1i <- glmer(Species_richness ~ IUCN_CAT + poly(log_elevation,3) + ag_suit
	+ (IUCN_CAT|SS) + (1|SSB) + (1|SSBS), 
	family = "poisson", data = data)

summary(m1i)

pos <- c(grep("4.5", names(fixef(m1i))),grep("7", names(fixef(m1i))),grep("1.5", names(fixef(m1i))))
y <- as.numeric(fixef(m1i)[pos])
se <- as.numeric(se.fixef(m1i)[pos])
yplus <- y + se*1.96
yminus <- y - se*1.96
y <-(exp(y)*100)
yplus<-(exp(yplus)*100)
yminus<-(exp(yminus)*100)

points <- c(100, y)
CI <- cbind(yplus, yminus)

plot(points ~ c(1,2,3,4), ylim = c(80,150), xlim = c(0.5,4.5),
	bty = "l", pch = 16, col = c(1,3,3,3), cex = 1.5,
	yaxt = "n", xaxt = "n",
	ylab = "Species richness difference (% � 95%CI)",
	xlab = "")
axis(1,seq(1,length(points),1), labels)
axis(2, c(80,100,120,140), c(80,100,120,140))

text(1, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "0")]), sep = " "))
text(2, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "4.5")]), sep = " "))
text(3, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "7")]), sep = " "))
text(4, 80, paste("n =", length(data$SS[which(data$IUCN_CAT == "1.5")]), sep = " "))

arrows(seq(2,length(points),1),CI[,1],
	seq(2,length(points),1),CI[,2], code = 3, length = 0.03, angle = 90)
abline(h = 100, lty = 2)
points(points ~ c(1,2,3,4), pch = 16, col = c(1,3,3,3), cex = 1.5)


#add points for master plot

IUCN.plot <- data.frame(label = labels[2:4], est = points[2:4], 
		upper = CI[,1], lower = CI[,2],
		n.site = c(length(data$SS[which(data$IUCN_CAT == "4.5")]), 
			length(data$SS[which(data$IUCN_CAT == "7")]),
			length(data$SS[which(data$IUCN_CAT == "1.5")])))
sp.plot2 <- rbind(sp.plot1, IUCN.plot)





# simple species richness for Zone data

sp.tropical <- subset(multiple.taxa.PA_11_14, Zone == "Tropical")
sp.temperate <- subset(multiple.taxa.PA_11_14, Zone == "Temperate")

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")

Sp.best.random.trop <- compare_randoms(sp.tropical, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

Sp.best.random.trop$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

Sp.best.random.temp <- compare_randoms(sp.temperate, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)

Sp.best.random.temp$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

# get polynomial relationships
sp.model.trop <- model_select(all.data  = sp.tropical, 
			     responseVar = "Species_richness", 
			     fitFamily = "poisson", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = Sp.best.random.trop$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
sp.model.trop$stats
#"Species_richness~poly(ag_suit,1)+poly(log_elevation,3)+Within_PA+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"

sp.model.temp <- model_select(all.data  = sp.temperate, 
			     responseVar = "Species_richness", 
			     fitFamily = "poisson", 
			     alpha = 0.05,
           fixedFactors= fF,
           fixedTerms= fT,
			     keepVars = keepVars,
           randomStruct = Sp.best.random.temp$best.random,
			     otherRandoms=character(0),
           verbose=TRUE)
sp.model.temp$stats
#"Species_richness~poly(log_elevation,1)+poly(log_slope,2)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"


# run models for plots
data.trop <- sp.model.trop$data
data.temp <- sp.model.temp$data

m1ztr <- glmer(Species_richness ~ Within_PA + poly(ag_suit,1)+poly(log_elevation,3)
	+ (1+Within_PA|SS)+ (1|SSBS)+ (1|SSB), family = "poisson",
	 data = sp.model.trop$data)

m1zte <- glmer(Species_richness ~ Within_PA +poly(log_slope,2) + poly(log_elevation,2) 
	+ (1+Within_PA|SS)+ (1|SSBS)+ (1|SSB), family = "poisson", 
	 data =  sp.model.temp$data)

#add results to master plot
ztr.est <- exp(fixef(m1ztr)[2])*100
ztr.upper <- exp(fixef(m1ztr)[2] + 1.96* se.fixef(m1ztr)[2])*100
ztr.lower <- exp(fixef(m1ztr)[2] - 1.96* se.fixef(m1ztr)[2])*100

zte.est <- exp(fixef(m1zte)[2])*100
zte.upper <- exp(fixef(m1zte)[2] + 1.96* se.fixef(m1zte)[2])*100
zte.lower <- exp(fixef(m1zte)[2] - 1.96* se.fixef(m1zte)[2])*100

a.zone <- data.frame(label = c("tropical", "temperate"),
				est = c(ztr.est, zte.est), 
				upper = c(ztr.upper, zte.upper), 
				lower = c(ztr.lower, zte.lower), 
				n.site = c(nrow(data.trop[which(data.trop$Within_PA == "yes"),]), 
					nrow(data.temp[which(data.temp$Within_PA == "yes"),])))
sp.plot3 <- rbind(sp.plot2, a.zone)


# species richness and taxon

plants <- subset(multiple.taxa.PA_11_14, taxon_of_interest == "Plants")
inverts <- subset(multiple.taxa.PA_11_14, taxon_of_interest == "Invertebrates")
verts <- subset(multiple.taxa.PA_11_14, taxon_of_interest == "Vertebrates")
nrow(plants)
nrow(inverts)
nrow(verts)

# check polynomials for confounding variables
fF <- c("Within_PA" ) 
fT <- list("ag_suit" = "3", "log_slope" = "3", "log_elevation" = "3")
keepVars <- list()
fI <- character(0)
RS <-  c("Within_PA")


best.random.p <- compare_randoms(plants, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)
best.random.p$best.random # "(1+Within_PA|SS)+ (1|SSB)"

best.random.i <- compare_randoms(inverts, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)
best.random.i$best.random # "(1+Within_PA|SS)+ (1|SSB)"

best.random.v <- compare_randoms(verts, "Species_richness",
				fitFamily = "poisson",
				siteRandom = TRUE,
				fixedFactors=fF,
        fixedTerms=fT,
        keepVars = keepVars,
        fixedInteractions=fI,
        otherRandoms=character(0),
				fixed_RandomSlopes = RS,
        fitInteractions=FALSE,
				verbose=TRUE)
best.random.v$best.random #"(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"

# get polynomial relationships
model.p <- model_select(all.data  = plants, 
				fitFamily = "poisson",
        responseVar = "Species_richness", 
        alpha = 0.05,
        fixedFactors= fF,
        fixedTerms= fT,
        keepVars = keepVars,
        randomStruct =best.random.p$best.random,
        otherRandoms=character(0),
        verbose=TRUE)
model.p$stats
#"Species_richness~poly(ag_suit,1)+poly(log_elevation,2)+poly(log_slope,3)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"

model.i <- model_select(all.data  = inverts, 
			  responseVar = "Species_richness", 
				fitFamily = "poisson",
        alpha = 0.05,
        fixedFactors= fF,
        fixedTerms= fT,
        keepVars = keepVars,
        randomStruct =best.random.i$best.random,
        otherRandoms=character(0),
        verbose=TRUE)
model.i$stats
#"Species_richness~poly(log_elevation,1)+poly(log_slope,1)+Within_PA+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"

model.v <- model_select(all.data  = verts, 
        responseVar = "Species_richness", 
				fitFamily = "poisson",
        alpha = 0.05,
        fixedFactors= fF,
        fixedTerms= fT,
        keepVars = keepVars,
        randomStruct =best.random.v$best.random,
        otherRandoms=character(0),
        verbose=TRUE)
model.v$stats
#"Species_richness~poly(ag_suit,3)+poly(log_elevation,2)+(1+Within_PA|SS)+(1|SSBS)+(1|SSB)"

data.p <- model.p$data
data.i <- model.i$data
data.v <- model.v$data

# run models
data.p <- plants[,c("Within_PA", "ag_suit", "log_elevation", "log_slope", "SS", "SSB", "SSBS", "Species_richness")]
data.p <- na.omit(data.p)
m1txp <- glmer(Species_richness ~ Within_PA + poly(ag_suit,1)+poly(log_elevation,2)+poly(log_slope,3)
	+ (Within_PA|SS)+ (1|SSB) + (1|SSBS), family = "poisson", 
	 data = data.p)

m1txi <- glmer(Species_richness ~ Within_PA +poly(log_elevation,1)+poly(log_slope,1) 
	+ (Within_PA|SS)+ (1|SSB)+ (1|SSBS), family = "poisson", 
	 data = data.i)

m1txv <- glmer(Species_richness ~ Within_PA + poly(ag_suit,3)+poly(log_elevation,2)
	+ (Within_PA|SS)+ (1|SSB)+ (1|SSBS), family = "poisson", 
	 data = data.v)

#add results to master plot
txp.est <- exp(fixef(m1txp)[2])*100
txp.upper <- exp(fixef(m1txp)[2] + 1.96* se.fixef(m1txp)[2])*100
txp.lower <- exp(fixef(m1txp)[2] - 1.96* se.fixef(m1txp)[2])*100

txi.est <- exp(fixef(m1txi)[2])*100
txi.upper <- exp(fixef(m1txi)[2] + 1.96* se.fixef(m1txi)[2])*100
txi.lower <- exp(fixef(m1txi)[2] - 1.96* se.fixef(m1txi)[2])*100

txv.est <- exp(fixef(m1txv)[2])*100
txv.upper <- exp(fixef(m1txv)[2] + 1.96* se.fixef(m1txv)[2])*100
txv.lower <- exp(fixef(m1txv)[2] - 1.96* se.fixef(m1txv)[2])*100



tax <- data.frame(label = c("plants", "inverts", "verts"),
				est = c(txp.est, txi.est, txv.est), 
				upper = c(txp.upper, txi.upper, txv.upper), 
				lower = c(txp.lower, txi.lower, txv.lower), 
				n.site = c(nrow(data.p[which(data.p$Within_PA == "yes"),]), 
					nrow(data.i[which(data.i$Within_PA == "yes"),]), 
					nrow(data.v[which(data.v$Within_PA == "yes"),])))
sp.plot <- rbind(sp.plot3, tax)


# test interaction term

best.random.test <- "(1+Within_PA|SS)+ (1|SSBS)+ (1|SSB)"
model.test <- model_select(all.data  = multiple.taxa.PA_11_14, 
			     responseVar = "Species_richness", 
				fitFamily = "poisson",
			     alpha = 0.05,
                       fixedFactors= c("Within_PA", "taxon_of_interest"),
                       fixedTerms= fT,
				fixedInteractions = "Within_PA:taxon_of_interest",
			     keepVars = keepVars,
                       randomStruct =best.random.test,
			     otherRandoms=character(0),
                       verbose=TRUE)

model.zone<- model_select(all.data  = multiple.taxa.PA_11_14, 
			     responseVar = "Species_richness", 
				fitFamily = "poisson",
			     alpha = 0.05,
                       fixedFactors= c("Within_PA", "Zone"),
                       fixedTerms= fT,
				fixedInteractions = "Within_PA:Zone",
			     keepVars = keepVars,
                       randomStruct =best.random.test,
			     otherRandoms=character(0),
                       verbose=TRUE)



# master plot

tiff( "simple models sp rich.tif",
	width = 10, height = 15, units = "cm", pointsize = 12, res = 300)

trop.col <- rgb(0.9,0,0)
temp.col <- rgb(0,0.1,0.7)
p.col <- rgb(0.2,0.7,0.2)
i.col <- rgb(0,0.7,0.9)
v.col <- rgb(0.9,0.5,0)

par(mar = c(9,6,4,1))
plot(1,1, 
	ylim = c(70,145), xlim = c(0.5,nrow(sp.plot)),
	bty = "l", 
	axes = F,
	ylab = "Species richness difference (%)",
	cex.lab = 1.5,
	xlab = "")
arrows(1:nrow(sp.plot),sp.plot$upper,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	lwd = 2,
	1:nrow(sp.plot),sp.plot$lower, code = 3, length = 0, angle = 90)
points(sp.plot$est ~ c(1:nrow(sp.plot)),
	pch = c(21, rep(16,4), rep(15,2),rep(17,3)), 
	lwd = 2,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	bg = "white", 
	cex = 1.5)
abline(v = c(2.5,5.5,7.5), col = 8)
abline(h= 100, lty = 2)
text(1:nrow(sp.plot),72, sp.plot$n.site, srt = 90, cex = 1)
axis(1, c(1:nrow(sp.plot)), sp.plot$label, cex.axis = 1.1, las = 2, tick = 0)
axis(2, c(80,100,120,140), c(80,100,120,140))

dev.off()


tiff( "simple models sp rich.tif",
	width = 10, height = 15, units = "cm", pointsize = 12, res = 300)

trop.col <- rgb(0.9,0,0)
temp.col <- rgb(0,0.1,0.7)
p.col <- rgb(0.2,0.7,0.2)
i.col <- rgb(0,0.7,0.9)
v.col <- rgb(0.9,0.5,0)

par(mar = c(9,6,4,1))
plot(1,1, 
	ylim = c(70,145), xlim = c(0.5,nrow(sp.plot)),
	bty = "l", 
	axes = F,
	ylab = "Species richness difference (%)",
	cex.lab = 1.5,
	xlab = "")
arrows(1:nrow(sp.plot),sp.plot$upper,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	lwd = 2,
	1:nrow(sp.plot),sp.plot$lower, code = 3, length = 0, angle = 90)
points(sp.plot$est ~ c(1:nrow(sp.plot)),
	pch = c(21, rep(16,4), rep(15,2),rep(17,3)), 
	lwd = 2,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	bg = "white", 
	cex = 1.5)
abline(v = c(2.5,5.5,7.5), col = 8)
abline(h= 100, lty = 2)
text(1:nrow(sp.plot),72, sp.plot$n.site, srt = 90, cex = 1)
axis(1, c(1:nrow(sp.plot)), sp.plot$label, cex.axis = 1.1, las = 2, tick = 0)
axis(2, c(80,100,120,140), c(80,100,120,140))


dev.off()


#new plot after text editing

sp.plot2 <- sp.plot[1:5,]

tiff( "simple models sp rich.tif",
	width = 8, height = 15, units = "cm", pointsize = 12, res = 300)

par(mar = c(9,6,4,2))
plot(1,1, 
	ylim = c(80,145), xlim = c(0.5,nrow(sp.plot2)+0.1),
	bty = "l", 
	axes = F,
	ylab = "Species richness difference (%)",
	cex.lab = 1.5,
	xlab = "")
abline(v = 2.5, lty = 2)
abline(h= 100, lty = 1, col = 8)
arrows(1:nrow(sp.plot2),sp.plot2$upper,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3), c(trop.col, temp.col, p.col, i.col, v.col)),
	lwd = 2,
	1:nrow(sp.plot2),sp.plot2$lower, code = 3, length = 0, angle = 90)
points(sp.plot2$est ~ c(1:nrow(sp.plot2)),
	pch = c(21, rep(16,4), rep(15,2),rep(17,3)), 
	lwd = 2,
	col = c(1,1,rep(rgb(0.5, 0.5, 0.5), 3)),
	bg = "white", 
	cex = 1.5)
text(1:nrow(sp.plot2),82, sp.plot2$n.site, srt = 90, cex = 1)
axis(1, c(1:nrow(sp.plot2)), sp.plot2$label, cex.axis = 1.1, las = 2, tick = 0)
axis(2, c(90,100,110,120,130,140), c(-10,0,10,20,30,40))

dev.off()


### effectiveness estimates
# benefit for species richness

b.sp <- exp(fixef(m1)[2]) -1
b.sp.max <- exp(fixef(m1)[2] + 1.96*se.fixef(m1)[2])-1
b.sp.min <- exp(fixef(m1)[2] - 1.96*se.fixef(m1)[2])-1


# if IUCN cat 1 or 2
pos <- which(names(fixef(m1i))== "IUCN_CAT1.5")
b.spIUCN1 <- exp(fixef(m1i)[pos])-1
b.spIUCN1.max <- exp(fixef(m1i)[pos] + 1.96*se.fixef(m1)[2])-1
b.spIUCN1.min <- exp(fixef(m1i)[pos] - 1.96*se.fixef(m1)[2])-1

# if IUCN cat  3 to 6
pos <- which(names(fixef(m1i))== "IUCN_CAT4.5")
b.spIUCN2 <- exp(fixef(m1i)[pos])-1
b.spIUCN2.max <- exp(fixef(m1i)[pos] + 1.96*se.fixef(m1)[2])-1
b.spIUCN2.min <- exp(fixef(m1i)[pos] - 1.96*se.fixef(m1)[2])-1


b.vals <- c(b.sp, b.sp.max, b.sp.min,
		b.spIUCN1, b.spIUCN1.max, b.spIUCN1.min,
		b.spIUCN2, b.spIUCN2.max, b.spIUCN2.min)

vals <- data.frame(name =  c("b.sp", "b.sp.max", "b.sp.min",
				"b.spIUCN1", "b.spIUCN1.max", "b.spIUCN1.min",
				"b.spIUCN2", "b.spIUCN2.max", "b.spIUCN2.min"),
			b.vals = b.vals, 
			metric = rep("sp.rich", 9), 
			NPA.abs = rep(NA,length(b.vals)),
			PA.abs = rep(NA,length(b.vals)),
			est = rep(NA,length(b.vals)))


#By 2005, we estimate that human impacts had reduced local richness by an average of 13.6% (95% CI: 9.1 � 17.8%) and 
#total abundance by 10.7% (95% CI: 3.8% gain � 23.7% reduction) compared with pre-impact times. 
#Approximately 60% of the decline in richness was independent of effects on abundance: 
#average rarefied richness has fallen by 8.1% (95% CI: 3.5 � 12.9%).
			
for(b in vals$b.vals){

benefit <- as.numeric(b)		# percentage increase in metric in PAs
PA.pct <- 15.6 				# percentage of total land area in PAs
# global loss of biodiversity (from Newbold et al)
if(vals$metric[which(vals$b.vals == b)] == "sp.rich"){
	global.loss <- 0.129			
	}else if (vals$metric[which(vals$b.vals == b)] == "abundance"){
	global.loss <- 0.126
	}else if (vals$metric[which(vals$b.vals == b)] == "rar.rich"){
	global.loss <- 0.081
	}

#0.129 for species-richness and 0.126 for abundance

NPA.rel <- 1-benefit			# relative biodiversity in unprotected sites
PA.rel <- 1					# biodiversity in protected sites
NPA.pct <- 100-PA.pct			# land area unprotected 
global.int <- 1-global.loss		# overall status of biodiversity relative to pristine


# we want NPA.abs and PA.abs - where these are the biodiv metrics in unprotected and protected relative to pristine
# simultaneous equations are

# global.int = NPA.pct/100*NPA.abs + PA.pct/100*PA.abs #overall loss is loss in PAs and nonPAs relative to pristine
# NPA.abs = PA.abs*NPA.rel			     


# so
#global.int = (NPA.pct/100)*PA.abs*NPA.rel + (PA.pct/100)*PA.abs
# which is the same as
#global.int = PA.abs*(NPA.pct/100*(NPA.rel) + PA.pct/100)

# then
PA.abs <- global.int/(PA.pct/100 + (NPA.pct/100 * (NPA.rel)))
NPA.abs <- PA.abs*NPA.rel
vals$NPA.abs[which(vals$b.vals == b)] <- NPA.abs
vals$PA.abs[which(vals$b.vals == b)] <- PA.abs

# if pristine is 1, then where between 1 and NPA.abs does PA.abs fall?
# get difference between PA.abs and NPA.abs as a percentage of NPA.abs
#((1-NPA.abs)-(1-PA.abs))/(1-NPA.abs)

est <- 1-(1-PA.abs)/(1-NPA.abs)
vals$est[which(vals$b.vals == b)] <- est

# ie
#est <- ((1-NPA.abs)-(1-PA.abs))/(1-NPA.abs)
}

vals



### working out area needed to achieve similar level of global biodiversity to increasing all existing to cat I-II
# method:
# if all PAs were IUCN cat 1 and still the same terrestrial % under protection, instead of what we have
# what would global loss be
# then how much area do we need to get this, given current benefit of PAs

# NPA abs remains the same as in normal benefit scenario
NPA.abs <- vals$NPA.abs[which(vals$name == c("b.sp"))]
# total area protected remains the same
PA.pct <- 15.4
# NPA.rel becomes 1-benefit of protection in IUCN category I - II
pos <- which(names(fixef(m1i))== "IUCN_CAT1.5")
NPA.rel <- 1 - (exp(fixef(m1i)[pos])-1)

#given
#global.int = (1 - PA.pct/100)*NPA.abs + (PA.pct/100)*PA.abs
global.int = (1 - PA.pct/100)*NPA.abs + (PA.pct/100)*(NPA.abs/NPA.rel)

#now, given the normal benefit, how much additional PA area needed to get this
# need area in terms of global.int and NPA abs. 
#global.int = (1 - PA.pct/100)*NPA.abs + (PA.pct/100)*NPA.abs/NPA.rel
#global.int == NPA.abs - (PA.pct/100)*NPA.abs  + (PA.pct/100)*NPA.abs/NPA.rel
#global.int = NPA.abs - (PA.pct/100)*(NPA.abs - NPA.abs/NPA.rel)
#(PA.pct/100) = (NPA.abs - global.int)/(NPA.abs - NPA.abs/NPA.rel)

NPA.rel <- 1 - (exp(fixef(m1)[2]) -1)
100*(NPA.abs - global.int)/(NPA.abs - NPA.abs/NPA.rel)
print("max")
NPA.rel <-  1 - (exp(fixef(m1)[2]+2*se.fixef(m1)[2]) -1)
100*(NPA.abs - global.int)/(NPA.abs - NPA.abs/NPA.rel)
print("min")
NPA.rel <-  1 - (exp(fixef(m1)[2]-2*se.fixef(m1)[2]) -1)
100*(NPA.abs - global.int)/(NPA.abs - NPA.abs/NPA.rel)


# what if all PAs are lower management restriction (i.e. new PAs only 3 - 6 and old PAs degraded)
# ie NPA.rel is only that for III to VI

pos <- which(names(fixef(m1i))== "IUCN_CAT4.5")
NPA.rel <- 1 - (exp(fixef(m1i)[pos])-1)
100*(NPA.abs - global.int)/(NPA.abs - NPA.abs/NPA.rel)







