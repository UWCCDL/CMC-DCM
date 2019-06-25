## Parameter analysis of the amazing SMM
library(lattice)
library(matlab)
library(viridis)
data <- read.table("data_A.txt", header = T, sep = "\t")

names(data)

# Remove participants who did not complete all tasks

count <- aggregate(data$Task, list(Subject=data$Subject), length)
complete <- subset(count, count$x ==6)
complete <- complete$Subject

d <- subset(data, data$Subject %in% complete)

for (name in names(d)[grep(".to.", names(d))]) {
  if (var(d[[name]]) == 0) {d[[name]] <- NULL}
}

for (name in names(d)[grep(".to.", names(d))]) {
  df <- data.frame(Subject = complete)
  for (t in unique(d$Task)) {
    sub <- subset(d, d$Task == t)
    df[[t]] <- sub[[name]]
  }
  #print(cor(df[2:7]))
  m <- cor(df[2:7])
  diag(m) <- 0
  png(paste(name, ".png", sep = ""), width = 5, height = 5, res = 300, units = "in")
  print(levelplot(m, col.regions=jet.colors(50), main=name, xlab="", ylab=""))
  #image(m)
  dev.off()
  print(paste(name, sum(sum(m))/30))
}

regions <- c("Action", "Declarative", "Perception", "Procedural", "WM")

eA <- read.table("All/smm_Ea.txt", header = F, sep=",")
pA <- read.table("All/smm_Pa.txt", header = F, sep=",")

eA[eA == 0] <- NA
pA[eA == 0] <- NA

colnames(eA) <- regions
rownames(eA) <- regions

colnames(pA) <- regions
rownames(pA) <- regions


png("eA.png", width=4, height=4, res=100, units="in")
levelplot(as.matrix(eA), col.regions=inferno(100), #heat.colors(100), 
          at=seq(-1.5, 0.2, length.out=100), 
          scales=list(x=list(rot=90)),
          colorkey=list(height=1), #axis.text="Strength (Hz)"),
          main="(A) Estimated Parameters",
          xlab="To", ylab="From", border="white")
#panel.grid()
dev.off()

png("pA.png", width=4, height=4, res=100, units="in")
levelplot(as.matrix(pA), col.regions=viridis(100), #jet.colors(100), 
          at=seq(0, 1, length.out=100), 
          scales=list(x=list(rot=90)), 
          main="(B) Posterior Probability of Parameters",
          xlab="To", ylab="From", border="white", lwd=2)
dev.off()