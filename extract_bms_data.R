# Extract data

library("R.matlab")
library("matlab")
library("colorspace")
library("MCMCpack")
library(lattice)
library(viridis)


tasks <- c("All", "Emotion Processing", "Incentive Processing", "Language, Math", 
           "Relational Reasoning", "Social Cognition", "Working Memory")

folders <- c("All", "Emotion", "Gambling", "Language", 
             "Relational", "Social", "WM")

model.names <- c("Common Model", "Hierarchical Open", "Hierarchical Closed", "Hub-and-spoke PFC", "Hub-and-spoke BG")

regions <- c("Action", "Declarative", "Perception", "Procedural", "WM")


get.task <- function(folder) {
  map <- data.frame(Folder = folders, Task = tasks)
  map$Task[map$Folder == folder]
}

load.data <- function(models=model.names) {
  res <- NULL

  for (fold in folders) {
    bms <- readMat(paste(fold, "BMS.mat", sep="/"))
    data <- bms$BMS
    # Likelihood
  
    like <- data[[1]][[1]][[4]]
    # RFX analysis
  
    alpha <- data[[1]][[1]][[5]][,,1]$alpha
    expect <- data[[1]][[1]][[5]][,,1]$exp.r
    exceed <- data[[1]][[1]][[5]][,,1]$xp
    pexceed <- data[[1]][[1]][[5]][,,1]$pxp
    partial <- data.frame(Model = models, Alpha = c(alpha),
                          Likelihood = c(like), Expected = c(expect),
                          Exceedance = c(exceed), PExceedance = c(pexceed),
                          Task = rep(get.task(fold), length(models)))
  
    if (is.null(res)) {
      res <- partial
    } else {
      res <- merge(res, partial, all=T)
    }
  }
  
  res
}

plot.task <- function(df, measure="Expected", back="#11775588", ...) {
  ymax <- max(max(d[[measure]]) * 1.1 , 1)
  par(mar=c(1.1, 4.1, 3.1, 1.1))
  if (length(unique(df$Task)) == 1) {
    x <- barplot(df[[measure]], beside = T, border = "white",
                 xlab="Architectures", ylab="Probability",
                 col="white", 
                 #names.arg = gsub(" ", "\n", df$Model),
                 ylim=c(0,ymax),
                 ...
    )
    rect(xleft = min(x)-1, ybottom = 0, xright = max(x + 1), ytop = ymax, 
           col=back, border="white", lwd=1, lty=3)
    grid()
    barplot(df[[measure]], beside = T, #legend.text = df[["Model"]], border = "white",
            xlab="Architectures", ylab="Probability",
            col=c(c("black"), grey.colors(4)), 
            border="white",
            #names.arg = df[["Model"]], 
            add=T, #fg="grey", col.axis="grey", col.lab="grey",
            ylim=c(0, ymax), #legend=T, 
            ...
    )
    text(x=x, y=df[[measure]] + ymax/25, 
         labels=format(round(df[[measure]], 3), nsmall=3))
    box(bty="o")
  }
}


plot.task2 <- function(df, measure="Expected", back="#11775588", ...) {
  ymax <- max(max(d[[measure]]) * 1.19 , 1)
  #par(mar=c(1.1, 4.1, 3.1, 1.1))
  if (length(unique(df$Task)) == 1) {
    x <- barplot(df[[measure]], beside = T, border = "white",
                 xlab="", ylab="", col.axis="white",
                 col="white",
                 #names.arg = gsub(" ", "\n", df$Model),
                 ylim=c(0,ymax),
                 yaxp=c(0,1,4),
                 ...
    )
    rect(xleft = min(x)-1, ybottom = 0, xright = max(x + 1), ytop = ymax, 
         col=back, border="white", lwd=1, lty=3)
    if (round(ymax, 0) == 1) {
      for (j in  seq(0, 1, 0.25)) {
        abline(h = j, lwd=1, lty=3, col="white")
      }
      for (j in  x) {
        abline(v = j, lwd=1, lty=3, col="white")
      }
    } else {
      # Then it's not a probability; use the default grid
      grid(lwd=1, col="white", ny = 5)
    } 
    
    yticklim <- max(round(ymax,-2),1)
    if (yticklim > ymax) {
      yticklim <- yticklim - 50
    }
    barplot(df[[measure]], beside = T, #legend.text = df[["Model"]], border = "white",
            xlab="", ylab="Probability", 
            col="grey35", 
            border="white",
            #names.arg =  paste(c("", "\n", "", "\n", ""), 
            #                   gsub(" ", "\n", model.names)),
            add=T, #fg="grey", col.axis="grey", col.lab="grey",
            ylim=c(0, ymax),  
            yaxp=c(0,yticklim,4),
            ...
    )
    #axis(2, at=seq(0, 1, 0.25), labels = seq(0, 1, 0.25))
    text(x=x, y=df[[measure]] + ymax/25, 
         labels=format(round(df[[measure]], 3), nsmall=3))
    #text(x=x, y=c(1, 0.8, 1, 0.8, 1), 
    #     labels=gsub(" ", "\n", model.names), adj = c(1/2,1))
    box(bty="n")
  }
}


plot.task3 <- function(df, measure="Expected", back="#11775588", ...) {
  ymax <- max(max(d[[measure]]) * 1.19 , 1)
  #par(mar=c(1.1, 4.1, 3.1, 1.1))
  if (length(unique(df$Task)) == 1) {
    x <- barplot(df[[measure]], beside = T, border = "white",
                 xlab="", ylab="", col.axis="white",
                 col="white",
                 #names.arg = gsub(" ", "\n", df$Model),
                 ylim=c(0,ymax),
                 yaxp=c(0,1,4),
                 ...
    )
    
    rect(xleft = min(x)-1, ybottom = 0, xright = max(x + 1), ytop = ymax, 
         #col=back,
         col="grey85",
         border="white", lwd=1, lty=3)
    if (round(ymax, 0) == 1) {
      for (j in  seq(0, 1, 0.25)) {
        abline(h = j, lwd=1, lty=3, col="white")
      }
      for (j in  x) {
        abline(v = j, lwd=1, lty=3, col="white")
      }
    } else {
      # Then it's not a probability; use the default grid
      grid(lwd=1, col="white", ny = 5)
    } 
    
    yticklim <- max(round(ymax,-2),1)
    
    if (yticklim > ymax) {
      yticklim <- yticklim - 50
    }
    kolors <- rainbow_hcl(5)
    
    shaded <- paste(kolors, "80", sep="")
    barplot(df[[measure]], beside = T, #legend.text = df[["Model"]], border = "white",
            xlab="", ylab="Probability", 
            col=shaded, 
            border=kolors,
            #names.arg =  paste(c("", "\n", "", "\n", ""), 
            #                   gsub(" ", "\n", model.names)),
            add=T, #fg="grey", col.axis="grey", col.lab="grey",
            ylim=c(0, ymax),  
            yaxp=c(0,yticklim,4),
            ...
    )
    #axis(2, at=seq(0, 1, 0.25), labels = seq(0, 1, 0.25))
    text(x=x, y=df[[measure]] + ymax/25, 
         labels=format(round(df[[measure]], 3), nsmall=3))
    #text(x=x, y=c(1, 0.8, 1, 0.8, 1), 
    #     labels=gsub(" ", "\n", model.names), adj = c(1/2,1))
    box(bty="n")
  }
}

generate.exp <- function(alphas, 
                         mnames = paste("M", 1:length(alphas), sep=""), 
                         res = 0.001) {
  p <- seq(0, 1, res)
  ii <- 1:length(alphas)
  dd <- NULL
  
  for (i in ii) {
    alpha <- alphas[i]
    others <- sum(alphas[ii != i])  # Dirichlet dist is agglomerative
    #print(c(alpha, others))   # Debug
    
    # Create the appropriate instantiation of the Dirichlet
    # Functions with two alpha values (each model vs. the rest)
    f <- function(x) {ddirichlet(c(x,  1 -x), alpha=c(alpha, others))}
    vf <- Vectorize(f)
    d <- vf(p)
    d[is.na(d)] <- 0
    dd <-cbind(dd, d)
    #print(dim(dd))
  }
  colnames(dd) <- mnames
  
  # Return
  dd
}

expected.prob <- function(d, p=NULL) {
  if (is.null(p)) {
    res <- 1 / (length(d) - 1)
    p <- seq(0, 1, res)
  }
  #p[d==max(d)]
  mean(p*d)
}

plot.model.dists <- function(dists, yup=max(dists), 
                             back="grey85", main="", annotate=T,
                             expected = T, ...) {
  #vals <- probs(dists)
  #plot.new()
  #plot.window(xlim=c(0,1), ylim=c(0,yup))
  n <- dim(dists)[2]
  k <- dim(dists)[1]
  x <- seq(0, 1, 1/(k-1))
  #print(x)
  plot.new()
  plot.window(xlim=c(0,1), ylim=c(0,yup), ...)
  rect(0, 0, 1.0, yup*1.2, col = back, border="white")
  grid(col="white")
  title(main=main)
  axis(2, at=seq(0, yup, 0.005))
  colors <- rainbow_hcl(n)
  for (i in 1:n) {
    lines(x=x, y=dists[,i], col=colors[i])
    # Polygons close by connecting the last point to the first.
    # so, we need to give the <x, y=0> coordinate of the first point.
    shaded <- rgb(t(col2rgb(colors[i])), maxColorValue = 255, alpha = 80)
    shaded <- paste(colors[i], "80", sep="")
    #print(shaded)
    polygon(x=c(x[x>=0], 0.5), y=c(dists[,i][x>=0], 0), col=shaded, border = NA)
    if (expected) {
      abline(v= 1000*expected.prob(dists[,i]), lty=3, lwd=2, col=colors[i])
    }
  }
}

plot.task4 <- function(df, yup=0.02, bgr="#11775588", ...) {
  ymax <- max(max(d[[measure]]) * 1.19 , 1)
  alphas <- df$Alpha
  dists <- generate.exp(alphas)
  dists[dists==Inf] <- 1
  dists <- dists/1000
  #par(mar=c(1.1, 4.1, 3.1, 1.1))
  if (length(unique(df$Task)) == 1) {
    plot.model.dists(dists, yup=yup, ...)
  }
}

plot.all.bytask <- function(data, task.list=tasks, measure="Expected", ...) {
  m <- NULL
  for (t in task.list) {
    sub <- subset(data, data$Task == t)
    sub <- c(sub[[measure]])
    print(sub)
    #names(sub) <- c(t)
    if (is.null(m)) {
      m <- sub
    } else {
      m <- rbind(m, sub)
    }
  }
  
  colnames(m) <- model.names
  rownames(m) <- tasks
  barplot(m, beside = T, legend = T, border = "white",
          xlab="Architectures", ylab="Probability",
          names.arg = gsub(" ", "\n", model.names),
          col = jet.colors(length(tasks)), ...)
  grid()
  box(bty="o")
  m
}

plot.all.bymodel <- function(data, measure="Expected", ...) {
  m <- NULL
  ymax <- max(max(d[[measure]]) * 1.1 , 1)
  for (t in tasks) {
    sub <- subset(data, data$Task == t)
    sub <- c(sub[[measure]])
    print(sub)
    #names(sub) <- c(t)
    if (is.null(m)) {
      m <- sub
    } else {
      m <- rbind(m, sub)
    }
  }
  
  colnames(m) <- model.names
  rownames(m) <- tasks
  kolors <- jet.colors(7)
  kolors <- c("#FFFFFF", rainbow_hcl(6, start=0.78))
  #kolors <- paste(kolors, "88", sep="")
  
  
  x <- barplot(t(m), beside = T, legend = F, border = "white",
          xlab="Architectures", ylab="Probability",
          #col = jet.colors(length(model.names)), ...)
          col="white", 
          names.arg = gsub(" ", "\n", tasks),
          ylim=c(0,ymax),
          ...
          )

  for (j in 1:7) {
    rect(xleft = x[1,j]-1, ybottom = 0, xright = x[1,j] + 5, ytop = ymax, 
         col=kolors[j], border="white", lwd=1, lty=3)
  }
  
  grid()
  
  barplot(t(m), beside = T, legend = T, border = "white",
          xlab="Architectures", ylab="Probability",
          #col = jet.colors(length(model.names)), ...)
          col=c(c("black"),grey.colors(4)), 
          names.arg = gsub(" ", "\n", tasks), add=T,
          ylim=c(0,ymax),
          ...
  )
  box(bty="o")
  m
}


calculate.relative.likelihood <- function(df) {
  df$RelativeLikelihood <- 0
  for (t in tasks) {
    df$RelativeLikelihood[df$Task == t] <- df$Likelihood[df$Task == t] - min(df$Likelihood[df$Task == t])
  }
  df
}

plot.super <- function(measure="Exceedance") {
  layout(matrix(1:8, ncol = 2, byrow = T), heights = c(1, 1, 1,1))
  kolors <- paste(rainbow_hcl(6, start=0.78), "AA", sep="")
  letters <- paste("(", c("A", "B", "C", "D", "E", "F", "G"), ")", sep="")
  for (i in 1:6) {
    sub <- subset(d, d$Task == tasks[i+1])
    par(mar=c(1.1, 3, 1.1, 1.1))
    if (i != 5) {
      plot.task2(sub, main=paste(letters[i], tasks[i+1]),  
                measure=measure, back=kolors[i])
    } else {
      plot.task2(sub, main=paste(letters[i], tasks[i+1]),  las=3,
                 measure=measure, back=kolors[i], 
                 names.arg =  gsub(" ", "\n", model.names))
      if (measure %in% c("Exceedance", "Exected")) {
        mtext(side = 2, text=paste(measure, "probability"), 
              line = 2, cex=par("cex"))
      } else {
        mtext(side = 2, text=paste(measure, "parameter"), 
              line = 2, cex=par("cex"))
      }
      axis(1, at=c(0.7, 1.9, 3.1, 4.3, 5.5), labels=rep("",5), col="black", lwd=2)
      
    }
  }
  plot.new()
  par(mar=c(1.1, 3, 1.1, 1.1))
  #plot.new()
  plot.task2(subset(d, d$Task=="All"), main="(G) All Tasks Combined",  
             measure=measure, back="grey90")
}


plot.uber <- function() {
  m1<-matrix(1:8, ncol = 2, byrow = T)
  m2<-matrix(9:16, ncol = 2, byrow = T)
  layout(cbind(m1, m2), heights = c(1, 1, 1,1))
  kolors <- c(paste(rainbow_hcl(6, start=0.78), "55", sep=""),"","",
              paste(rainbow_hcl(6, start=0.78), "DD", sep=""))
  
  letters <- paste("(", c("A", "B", "C", "D", "E", "F", "", "G",
                          "H", "I", "J", "K", "L", "M"), ")", sep="")
  measure<-"Expected"
  for (i in 1:6) {
    sub <- subset(d, d$Task == tasks[i+1])
    par(mar=c(1.1, 3, 1.1, 0.1))
    if (i != 5) {
      plot.task2(sub, main=paste(letters[i], tasks[i+1]),  
                 measure=measure, back=kolors[i])
    } else {
      plot.task2(sub, main=paste(letters[i], tasks[i+1]),  las=3,
                 measure=measure, back=kolors[i], 
                 names.arg =  gsub(" ", "\n", model.names))
      if (measure %in% c("Exceedance", "Exected")) {
        mtext(side = 2, text=paste(measure, "probability"), 
              line = 2, cex=par("cex"))
      } else {
        mtext(side = 2, text=paste(measure, "parameter"), 
              line = 2, cex=par("cex"))
      }
      axis(1, at=c(0.7, 1.9, 3.1, 4.3, 5.5), labels=rep("",5), col="black", lwd=2)
      
    }
  }
  plot.new()
  par(mar=c(1.1, 3, 1.1, 0.1))
  #plot.new()
  plot.task2(subset(d, d$Task=="All"), main="(G) All Tasks Combined",  
             measure=measure, back="grey90")
  
  measure<-"Exceedance"
  for (i in 9:14) {
    sub <- subset(d, d$Task == tasks[i-7])
    par(mar=c(1.1, 3, 1.1, 0.1))
    if (i != 13) {
      plot.task2(sub, main=paste(letters[i], tasks[i-7]),  
                 measure=measure, back=kolors[i])
    } else {
      plot.task2(sub, main=paste(letters[i], tasks[i-7]),  las=3,
                 measure=measure, back=kolors[i], 
                 names.arg =  gsub(" ", "\n", model.names))
      if (measure %in% c("Exceedance", "Exected")) {
        mtext(side = 2, text=paste(measure, "probability"), 
              line = 2, cex=par("cex"))
      } else {
        mtext(side = 2, text=paste(measure, "parameter"), 
              line = 2, cex=par("cex"))
      }
      axis(1, at=c(0.7, 1.9, 3.1, 4.3, 5.5), labels=rep("",5), col="black", lwd=2)
      
    }
  }
  plot.new()
  par(mar=c(1.1, 3, 1.1, 0.1))
  #plot.new()
  plot.task2(subset(d, d$Task=="All"), main="(M) All Tasks Combined",  
             measure=measure, back="grey90")
}


plot.uber2 <- function() {
  m1<-matrix(1:8, ncol = 2, byrow = T)
  m2<-matrix(9:16, ncol = 2, byrow = T)
  layout(cbind(m1, m2), heights = c(1, 1, 1,1))
  kolors <- c(paste(rainbow_hcl(6, start=0.78), "55", sep=""),"","",
              paste(rainbow_hcl(6, start=0.78), "DD", sep=""))
  
  letters <- paste("(", c("A", "B", "C", "D", "E", "F", "", "G",
                          "H", "I", "J", "K", "L", "M"), ")", sep="")
  measure<-"Expected"
  for (i in 1:6) {
    sub <- subset(d, d$Task == tasks[i+1])
    par(mar=c(1.1, 3, 1.1, 0.1))
    if (i != 5) {
      plot.task4(sub, yup=0.02, main=paste(letters[i], tasks[i+1]),
                 back="grey85")
    } else {
      plot.task4(sub, yup=0.02, main=paste(letters[i], tasks[i+1]),
                 back="grey85")
      axis(1, at=seq(0, 1, 0.25))
      mtext(side = 2, text=paste(measure, "Probability Density"), 
            line = 2, cex=par("cex"))
      mtext(side = 1, text=paste(measure, "Probability"), 
            line = 2, cex=par("cex"))
    }
  }
  plot.new()
  legend(x="center", legend=model.names, pch = 21, 
         col=rainbow_hcl(5), pt.bg = paste(rainbow_hcl(5), "50", sep=""))
  par(mar=c(1.1, 3, 1.1, 0.1))
  #plot.new()
  plot.task4(subset(d, d$Task=="All"), 
             main="(G) All Tasks Combined",
             back="grey85")
  
  measure<-"Exceedance"
  for (i in 9:14) {
    sub <- subset(d, d$Task == tasks[i-7])
    par(mar=c(1.1, 3, 1.1, 0.1))
    if (i != 13) {
      plot.task3(sub, main=paste(letters[i], tasks[i-7]),  
                 measure=measure, back=kolors[i])
    } else {
      plot.task3(sub, main=paste(letters[i], tasks[i-7]),  las=3,
                 measure=measure, back=kolors[i], 
                 names.arg =  gsub(" ", "\n", model.names))
      if (measure %in% c("Exceedance", "Exected")) {
        mtext(side = 2, text=paste(measure, "probability"), 
              line = 2, cex=par("cex"))
      } else {
        mtext(side = 2, text=paste(measure, "parameter"), 
              line = 2, cex=par("cex"))
      }
      axis(1, at=c(0.7, 1.9, 3.1, 4.3, 5.5), labels=rep("",5), col="black", lwd=2)
      
    }
  }
  plot.new()
  par(mar=c(1.1, 3, 1.1, 0.1))
  #plot.new()
  plot.task3(subset(d, d$Task=="All"), main="(M) All Tasks Combined",  
             measure=measure, back="grey90")
}


plot.uber3 <- function() {
  #m1<-matrix(1:9, ncol = 3, byrow = T)
  m1 <- matrix(c(1, 1, 2, 2, 3, 3,
                 4, 4, 5, 5, 6, 6,
                 8, 8, 9, 9, 10, 10,
                 7, 7, 7, 7, 7, 7), ncol=6, byrow=T)
  layout(m1, heights=c(1,1,1,0.2))
  kolors <- c(paste(rainbow_hcl(6, start=0.78), "55", sep=""),"","",
              paste(rainbow_hcl(6, start=0.78), "DD", sep=""))
  
  letters <- paste("(", c("A", "B", "C", "D", "E", "F", "", "G"), ")", sep="")
  measure<-"Expected"
  
  # Emotion
  sub <- subset(d, d$Task == tasks[2])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(A) Emotion Processing",
             back="grey85")
  
  # Incentive
  sub <- subset(d, d$Task == tasks[3])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(B) Incentive Processing",
             back="grey85")
  
  # Language/Math
  sub <- subset(d, d$Task == tasks[4])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(C) Language and Math",
             back="grey85")
  
  # Relational
  sub <- subset(d, d$Task == tasks[5])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(D) Relational Reasoning",
             back="grey85")
  
  # Social
  sub <- subset(d, d$Task == tasks[6])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(E) Social Cognition",
             back="grey85")
  
  # Working Memory
  sub <- subset(d, d$Task == tasks[7])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(F) Working Memory",
             back="grey85")

  # Empty row
  par(mar=rep(0,4))
  plot.new()
  
  # Empty with legend
  plot.new()
  par(mar=rep(0,4)+0.1)
  legend(x="center", legend=model.names, pch = 21, 
         col=rainbow_hcl(5), cex=1.25, bty = "n",
         pt.bg = paste(rainbow_hcl(5), "50", sep="")
  )
    
  # All Tasks
  sub <- subset(d, d$Task == tasks[7])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(subset(d, d$Task=="All"), 
             main="(G) All Tasks Combined",
             back="grey85")
  #box(bty="o", which="figure", lwd=1, col="grey")
  axis(1, at=seq(0, 1, 0.25))
  mtext(side = 2, text=paste(measure, "Probability Density"), 
        line = 2, cex=par("cex"))
  mtext(side = 1, text=paste("Probability"), 
        line = 2, cex=par("cex"))
  
  # Exceedances
  par(mar=c(1.1, 3, 2.1, 1.1))
  plot.summary.exceedance()
  title(main="(H) Exceedance Probabilities", xlab="Exceedance Probabilities")
  #axis(2)
  mtext(side = 2, text="Tasks", 
        line = 1, cex=par("cex"))
  mtext(side = 1, text=paste("Exceedance Probability"), 
        line = 2, cex=par("cex"))
}


plot.uber4 <- function(expected = TRUE) {
  #m1<-matrix(1:9, ncol = 3, byrow = T)
  m1 <- matrix(c(1, 1, 2, 2, 3, 3,
                 4, 4, 5, 5, 6, 6,
                 8, 8, 9, 9, 9, 9,
                 7, 7, 7, 7, 7, 7), ncol=6, byrow=T)
  layout(m1, heights=c(1,1,1,0.2))
  kolors <- c(paste(rainbow_hcl(6, start=0.78), "55", sep=""),"","",
              paste(rainbow_hcl(6, start=0.78), "DD", sep=""))
  
  letters <- paste("(", c("A", "B", "C", "D", "E", "F", "", "G"), ")", sep="")
  measure<-"Expected"
  
  # Emotion
  sub <- subset(d, d$Task == tasks[2])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(A) Emotion Processing",
             back="grey85")
  
  # Incentive
  sub <- subset(d, d$Task == tasks[3])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(B) Incentive Processing",
             back="grey85")
  
  # Language/Math
  sub <- subset(d, d$Task == tasks[4])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(C) Language and Math",
             back="grey85")
  
  # Relational
  sub <- subset(d, d$Task == tasks[5])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(D) Relational Reasoning",
             back="grey85")
  
  # Social
  sub <- subset(d, d$Task == tasks[6])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(E) Social Cognition",
             back="grey85")
  
  # Working Memory
  sub <- subset(d, d$Task == tasks[7])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(sub, yup=0.02, main="(F) Working Memory",
             back="grey85")
  
  # Empty row, cell 7
  par(mar=rep(0,4))
  plot.new()
  
  
  
  # All Tasks
  sub <- subset(d, d$Task == tasks[7])
  par(mar=c(1.1, 3, 2.1, 0.1))
  plot.task4(subset(d, d$Task=="All"), 
             main="(G) All Tasks Combined",
             back="grey85")
  #box(bty="o", which="figure", lwd=1, col="grey")
  legend(x="top", legend=model.names, pch = 21, 
         col=rainbow_hcl(5), cex=1, bty = "n",
         pt.bg = paste(rainbow_hcl(5), "50", sep="")
  )
  axis(1, at=seq(0, 1, 0.25))
  mtext(side = 2, text=paste(measure, "Probability Density"), 
        line = 2, cex=par("cex"))
  mtext(side = 1, text=paste("Probability"), 
        line = 2, cex=par("cex"))
  
  # Exceedances
  par(mar=c(1.1, 12, 2.1, 1.1))
  plot.summary.exceedance2()
  title(main="(H) Exceedance Probabilities", xlab="Exceedance Probabilities")
  #axis(2)
  mtext(side = 2, text="Tasks", 
        line = 10, cex=par("cex"))
  mtext(side = 1, text=paste("Exceedance Probability"), 
        line = 2, cex=par("cex"))
}

  #plot.new()
  #par(mar=c(1.1, 3, 1.1, 0.1))
  #plot.new()
  #plot.task3(subset(d, d$Task=="All"), main="(M) All Tasks Combined",  
  #           measure=measure, back="grey90")
  #}
#}

## Final

plot.summary.exceedance <- function() {
  colors <- rainbow_hcl(5)
  nd <- d
  nd$Task <- as.character(nd$Task)
  nd$Task[nd$Task=="All"] <-"Z"
  
  nd <- nd[order(nd$Task, nd$Model),]
  m <- matrix(nd$Exceedance, ncol=7, byrow=F)
  #par(mar=c(3,10,1,1))
  gtasks <- unique(nd$Task)
  gtasks <- gtasks[order(gtasks)]
  gtasks[7] <- "All Tasks Combined"
  ys=barplot(m, col = paste(colors, "90", sep=""), border=colors, horiz = T,
          las=1, xlab="Exceedance Prob", ylab="Tasks")
  text(x=0, y=ys, labels = gtasks, adj = c(0,1/2))
}

plot.summary.exceedance2 <- function() {
  colors <- rainbow_hcl(5)
  nd <- d
  nd$Task <- as.character(nd$Task)
  nd$Task[nd$Task=="All"] <-"Z"
  
  nd <- nd[order(nd$Task, nd$Model),]
  m <- matrix(nd$Exceedance, ncol=7, byrow=F)
  #par(mar=c(3,10,1,1))
  gtasks <- unique(nd$Task)
  gtasks <- gtasks[order(gtasks)]
  gtasks[7] <- "All Tasks Combined"
  ys=barplot(m, col = paste(colors, "90", sep=""), border=colors, horiz = T,
             las=1, names.arg = gtasks, xlab="Exceedance Prob")
  text(x = m[1,]/2, y=ys, labels=format(m[1,], digits=2), col="black")
  text(x = m[1,3:4] + m[3,3:4]/2, y=ys[3:4], labels=format(m[3,3:4], digits=1), col="black")
  #text(x=0, y=ys, labels = gtasks, adj = c(0,1/2))
}

plot.pmatrix <- function(m) {
  m[m == 0] <- NA
  m[is.nan(m)] <- NA
  colnames(m) <- regions
  rownames(m) <- regions
  
  levelplot(as.matrix(m), col.regions=viridis(100), #heat.colors(100), 
            at=seq(0.5, 1, length.out=100), 
            scales=list(x=list(rot=90)),
            colorkey=list(height=1), #axis.text="Strength (Hz)"),
            main="(A) Estimated Parameters",
            xlab="To", ylab="From", border="white")
}


plot.params <- function() {
  mlay <- matrix(c(1,2,3,4,5,6,7,7,7), ncol = 3, byrow = T)
  layout(mlay, heights = c(1,1,0.2))
  #par(mfrow=c(2,3))
  for (task in folders[2:7]) {
    m <- read.table(paste(task, "avg", "pA.txt", sep="_"), sep=",")
    m <- as.matrix(m)
    #m[is.nan(m)] <- 0
    row.names(m) <- regions
    colnames(m) <- regions
    plot(as.matrix(m), col=viridis(10), main=task)
  }
  
  for (j in 1:3){plot.new()}
}

plot.optimized <- function() {
  m <- matrix(rep(0,25), ncol=5)
  for (task in folders[2:7]) {
    partial <- read.table(paste(task, "optimized", "avg", "A.txt", sep="_"), sep=",")
    partial <- as.matrix(partial)
    partial[is.nan(partial)] <- 0
    m <- m + partial
  }
  
  colnames(m) <- regions
  rownames(m) <- regions
  m[m==0] <- NA
  levelplot(as.matrix(m), col.regions=viridis(100), #heat.colors(100), 
            at=seq(0, 6, length.out=100), 
            scales=list(x=list(rot=90)),
            colorkey=list(height=1), #axis.text="Strength (Hz)"),
            main="Optimized parameters",
            xlab="To", ylab="From", border="white")
}

d <- load.data()

for (measure in c("Alpha", "Expected", "Exceedance")) {
  png(file=paste(measure, "bytask.png", sep="."), res = 300,
      width = 9, height = 5, units = "in")
  ymax <- max(max(d[[measure]]) * 1.1 , 1)
  plot.all.bytask(d, measure = measure, main = measure, ylim = c(0, ymax))
  dev.off()
  
  png(file=paste(measure, "bymodel.png", sep="."), res = 300,
      width = 9, height = 5, units = "in")
  plot.all.bymodel(d, measure = measure, main = measure)
  dev.off()
  kolors <- c("#FFFFFF", rainbow_hcl(6, start=0.78))
  for (i in 1:7) {
    
      png(file=paste(measure, tasks[i], "bymodel.png", sep="."), 
          res = 100,
          width = 5, height = 3, units = "in")
      sub <- subset(d, d$Task == tasks[i])
      if (i <= 2) {
        plot.task(sub, main=tasks[i],  
                  measure=measure, back=kolors[i], legend.text=sub$Model)
        #legend("topright", legend = sub$Model, col=c("black", grey.colors(4)))
      } else {
        plot.task(sub, main=tasks[i], 
                  measure=measure, back=kolors[i])
      }
      dev.off()
      
      if (measure == "Alpha") {
        
        png(file=paste("dist", tasks[i], "bymodel.png", sep="."), 
            res = 100,
            width = 5, height = 3, units = "in")
        sub <- subset(d, d$Task == tasks[i])
        par(mar=c(2.1, 3, 2.1, 0.1))
        plot.task4(sub, yup=0.02, main=paste(tasks[i]),
                   back="grey85")
        axis(1, at=seq(0, 1, 0.25))
        mtext(side = 2, text=paste("Probability Density"), 
              line = 2, cex=par("cex"))
        mtext(side = 1, text=paste(measure, "Probability"), 
              line = 2, cex=par("cex"))
        
        if (tasks[i] == "Emotion Processing") {
          legend(x="topright", legend=model.names, pch = 21, 
                 col=rainbow_hcl(5), pt.bg = paste(rainbow_hcl(5), "50", sep=""),
                 bg=NA, bty="n")
        }
        dev.off()
      }
  }
  
  for (i in 1:7) {
    png(file=paste(measure, tasks[i], "bymodel2.png", sep="."), 
        res = 100,
        width = 5, height = 3, units = "in")
    sub <- subset(d, d$Task == tasks[i])
    if (i <= 2) {
      plot.task2(sub, main=tasks[i],  
                measure=measure, back=kolors[i], legend.text=sub$Model)
      #legend("topright", legend = sub$Model, col=c("black", grey.colors(4)))
    } else {
      plot.task2(sub, main=tasks[i], 
                measure=measure, back=kolors[i])
      
    }
    dev.off()
  }
  
  ## Summary pretty figures
  png(paste(measure, "pretty.png", sep="_"), 
      width=5, height = 6, res = 300, units = "in")
  plot.super(measure=measure)
  dev.off()
}

png("uber3.png", 
    width=7, height = 5, res = 300, units = "in")
plot.uber3()
dev.off()

png("uber4.png", 
    width=7, height = 5, res = 300, units = "in")
plot.uber4()
dev.off()

## VOI data

rois <- c("Action", "LTM", "Perception", "Procedural", "WM")
vdata <- NULL
for (j in 2:7) {
  for (roi in rois) {
    sub <- read.table(paste(folders[j], "/", roi, "_xyz.txt", sep=""),
                      header=T)
    sub$Task <- tasks[j]
    if (is.null(vdata)) {
      vdata <- sub
    } else {
      vdata <- merge(vdata, sub, all=T)
    }  
  }
}
names(vdata) <- c("Subject", "ROI", "x", "y", "z", "Size", "Task")
library(ggplot2)
vdata$Radius <- 8
vdata$Radius[vdata$ROI == "Procedural"] <- 6
#vdata$Size <- as.numeric(vdata$Size)

ggplot(vdata, aes(x=ROI, y=Size, fill=ROI)) + 
  geom_boxplot() +
  facet_wrap(~ Task)


ggplot(vdata, aes(x=Task, y=Size, col=Task, marker=Radius)) + 
  #geom_point() +
  stat_summary(fun.data = mean_sdl, aes(size=Radius)) +
  scale_size(range = c(0.5,1)) +
  facet_wrap(~ ROI) +
  theme(axis.text.x = element_text(angle = 90))

ggplot(vdata, aes(x=ROI, y=Size, col=ROI, size=Radius)) + 
  stat_summary(fun.data = mean_sdl) +
  scale_size(range = c(0.5,1)) +
  facet_wrap(~ Task) +
  ylab("Size (number of voxels)") +
  theme(axis.text.x = element_text(angle = 90))

ggsave("vois_size.png", width = 7, height = 5, units = "in")

