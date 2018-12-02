##################################################################
#        SNP Selection using Random Forest, SFFS, and SVR        #
#                    Dani Setiawan G651150281                    #
##################################################################
# Please install the following packages before running this code!
# scrime, kernlab, randomForest, doParallel, gtools
##################################################################
# Missing symbol replacement
toNA <- function(data, missing.symbol,
                 type.col.id, geno.col.id, pheno.col.id){
  if(!is.data.frame(data)) data <- as.data.frame(data)
  type <- data[,type.col.id]
  phenotype <- data[,pheno.col.id]
  genotype <- as.matrix(data)[,geno.col.id]
  genotype[which(genotype == missing.symbol)] <- NA
  return(list(type = type, phenotype = phenotype,
              genotype = as.data.frame(genotype)))
}
##################################################################
# Missing call filter
mc.filter <- function(genotype, col.mcr, row.mcr){
  if(col.mcr < 0 | row.mcr < 0 | 1 < col.mcr | 1 < row.mcr)
    stop(message("Missing call rate must be [0, 1]!"))
  
  geno.dim <- dim(genotype)
  removed.cols <- vector("numeric")
  for(col in 1:geno.dim[2]){
    n.NA <- sum(is.na(genotype[,col]))
    if((col.mcr < 1 & n.NA/geno.dim[1] > col.mcr) |
       (col.mcr == 1 & n.NA/geno.dim[1] == col.mcr))
      removed.cols <- c(removed.cols, col)
  }
  if(length(removed.cols != 0)){
    genotype <- genotype[,-removed.cols]
    geno.dim <- dim(genotype)
  }
  else removed.cols <- NULL
  
  removed.rows <- vector("numeric")
  for(row in 1:geno.dim[1]){
    n.NA <- sum(is.na(genotype[row,]))
    if((row.mcr < 1 & n.NA/geno.dim[2] > row.mcr) |
       (row.mcr == 1 & n.NA/geno.dim[2] == row.mcr))
      removed.rows <- c(removed.rows, row)
  }
  if(length(removed.rows != 0))
    genotype <- genotype[-removed.rows,]
  else removed.rows <- NULL
  return(list(genotype = genotype, removed.rows = removed.rows,
              removed.cols = removed.cols))
}
##################################################################
# Calculation of optimality/selection criterion value
fitness <- function(x, y, criterion = c("mse", "adjR2"),
                    kernel = "besseldot", kpar = list(),
                    scaled = TRUE, cost = 10, cv = 10){
  if(!is.matrix(x)) x <- as.matrix(x)
  criterion <- match.arg(criterion)
  if(criterion == "mse"){
    mse <- NA
    for(i in cost){
      mse[i] <- kernlab::ksvm(x, y, scaled = scaled,
                              type = "eps-svr",
                              kernel = kernel, kpar = kpar,
                              C = i, cross = cv)@error
    }
    cost <- which.min(mse)
    value <- min(mse, na.rm = TRUE)
  }
  else if(criterion == "adjR2"){
    adjR2 <- NA
    for(i in cost){
      model <- kernlab::ksvm(x, y, scaled = scaled,
                             type = "eps-svr",
                             kernel = kernel, kpar = kpar,
                             C = i, cross = cv)
      pred.y <- kernlab::predict(model, x)
      corr <- as.vector(cor(y, pred.y, method = "pearson"))
      adjR2[i] <- 1-(1-corr^2)*(length(y)-1)/(length(y)-ncol(x)-1)
    }
    cost <- which.max(adjR2)
    value <- max(adjR2, na.rm = TRUE)
  }
  return(list(cost = cost, value = value))
}
##################################################################
# Sequential backward elimination
sbe.svr <- function(x, y, var.index = 1:ncol(x), 
                    criterion = c("mse", "adjR2"),
                    n.count = length(var.index) - 1,
                    kernel = "besseldot", kpar = list(),
                    scaled = TRUE, cost = 10, cv = 10){
  if(!is.matrix(x)) x <- as.matrix(x)
  if(!is.vector(y)) y <- as.vector(y)
  if(!is.vector(var.index)) var.index <- as.vector(var.index)
  if(is.list(var.index)) var.index <- unlist(var.index)
  if(n.count < 1)
    stop(message("Number of elimination step must at least be 1!"))
  n.var <- ncol(x)
  criterion <- match.arg(criterion)
  fit <- NA
  fit[n.var+1] <- fitness(x[,var.index], y,
                          criterion = criterion,
                          kernel = kernel, kpar = kpar,
                          scaled = scaled, cost = cost,
                          cv = cv)$value
  prev.selected.var <- vector("character")
  selected.var <- colnames(x)[var.index]
  count <- 1
  mse <- adjR2 <- NA
  suppressWarnings(require(foreach, quietly = TRUE, lib.loc = R.lib.loc))
  while(!setequal(selected.var, prev.selected.var) &
        count <= n.count){
    fit[var.index] <- foreach(i = var.index, .combine = 'c',
                              .export = "fitness") %dopar% {
                                fitness(x[,var.index[-which(var.index == i)]], y,
                                        criterion = criterion,
                                        kernel = kernel, kpar = kpar,
                                        scaled = scaled, cost = cost,
                                        cv = cv)$value
                              }
    prev.selected.var <- selected.var
    removed.index <- {
      if(criterion == "mse")
        which(var.index == which.min(fit))
      else if(criterion == "adjR2")
        which(var.index == which.max(fit))
    }
    if(length(removed.index) != 0)
      var.index <- var.index[-removed.index]
    selected.var <- colnames(x)[var.index]
    if(!setequal(selected.var, prev.selected.var)){
      cat("Backward Elimination:",
          setdiff(prev.selected.var, selected.var),
          "removed!", "\n")
      cat(selected.var, "\n")
      if(criterion == "mse"){
        mse <- min(fit, na.rm = TRUE)
        cat("Mean squared error:", mse, "\n")
      }
      else if(criterion == "adjR2"){
        adjR2 <- max(fit, na.rm = TRUE)
        cat("Adjusted R squared:", adjR2, "\n")
      }
    }
    else cat("Backward Elimination: None removed!\n")
    count <- count + 1
  }
  return(list(adjR2 = adjR2, mse = mse,
              selected.var = selected.var,
              var.index = var.index))
}
##################################################################
# Sequential forward selection
sfs.svr <- function(x, y, var.index = NULL,
                    criterion = c("mse", "adjR2"), n.count = Inf,
                    kernel = "besseldot", kpar = list(),
                    scaled = TRUE, cost = 10, cv = 10){
  if(!is.matrix(x)) x <- as.matrix(x)
  if(!is.vector(y)) y <- as.vector(y)
  if(!is.vector(var.index)) var.index <- as.vector(var.index)
  if(is.list(var.index)) var.index <- unlist(var.index)
  if(n.count < 1)
    stop(message("Number of selection step must at least be 1!"))
  n.var <- ncol(x)
  criterion <- match.arg(criterion)
  fit <- NA
  if(!is.null(var.index)){
    fit[var.index] <- fitness(x[,var.index], y,
                              criterion = criterion,
                              kernel = kernel, kpar = kpar,
                              scaled = scaled, cost = cost,
                              cv = cv)$value
  }
  selected.var <- colnames(x)[var.index]
  count <- 1
  mse <- adjR2 <- NA
  suppressWarnings(require(foreach, quietly = TRUE, lib.loc = R.lib.loc))
  while(!any(duplicated(selected.var)) & count <= n.count){
    index <- {
      if(is.null(var.index)) 1:n.var
      else (1:n.var)[-var.index]
    }
    if(length(index) == 0) break
    fit[index] <- foreach(i = index, .combine = 'c',
                          .export = "fitness") %dopar% {
                            fitness(x[,c(var.index,i)], y,
                                    criterion = criterion,
                                    kernel = kernel, kpar = kpar,
                                    scaled = scaled, cost = cost,
                                    cv = cv)$value
                          }
    var.index <- {
      if(criterion == "mse")
        c(var.index, which.min(fit))
      else if(criterion == "adjR2")
        c(var.index, which.max(fit))
    }
    selected.var <- colnames(x)[var.index]
    if(!any(duplicated(selected.var))){
      cat("Forward Selection:", tail(selected.var, 1L),
          "added!", "\n")
      cat(selected.var, "\n")
      if(criterion == "mse"){
        mse <- min(fit, na.rm = TRUE)
        cat("Mean squared error:", mse, "\n")
      }
      else if(criterion == "adjR2"){
        adjR2 <- max(fit, na.rm = TRUE)
        cat("Adjusted R squared:", adjR2, "\n")
      }
    }
    else cat("Forward Selection: None added!\n")
    count <- count + 1
  }
  return(list(adjR2 = adjR2, mse = mse,
              selected.var = unique(selected.var),
              var.index = unique(var.index)))
}
##################################################################
# Sequential Forward Floating Selection
sffs.svr <- function(x, y, var.index = NULL,
                     criterion = c("mse", "adjR2"),
                     kernel = "besseldot", kpar = list(),
                     scaled = TRUE, cost = 10, cv = 10){
  if(!is.matrix(x)) x <- as.matrix(x)
  if(!is.vector(y)) y <- as.vector(y)
  if(!is.vector(var.index)) var.index <- as.vector(var.index)
  if(is.list(var.index)) var.index <- unlist(var.index)
  criterion <- match.arg(criterion)
  prev.selected.var <- NA
  selected.var <- colnames(x)[var.index]
  while(!setequal(selected.var, prev.selected.var)){
    if(length(selected.var) > 2){
      SBE <- sbe.svr(x, y, var.index = var.index,
                     criterion = criterion,
                     kernel = kernel, kpar = kpar,
                     scaled = scaled, cost = cost, cv = cv)
      var.index <- SBE$var.index
    }
    prev.var.index <- var.index
    prev.selected.var <- colnames(x)[prev.var.index]
    SFS <- sfs.svr(x, y, var.index = var.index,
                   criterion = criterion, n.count = 1,
                   kernel = kernel, kpar = kpar,
                   scaled = scaled, cost = cost, cv = cv)
    var.index <- SFS$var.index
    selected.var <- colnames(x)[var.index]
  }
  return(list(adjR2 = SFS$adjR2, mse = SFS$mse,
              selected.var = selected.var,
              var.index = var.index))
}
##################################################################
select <- function(x, y, n.tree = 500,
                   set.mtry = c("default", "tuned", "complete"),
                   vim.type = c("rss", "mse"),
                   n.searched.var = ncol(x),
                   n.most.imp = n.searched.var,
                   kernel = "besseldot", kpar = list(),
                   scaled = TRUE, cost = 10, cv = 10){
  start <- Sys.time()
  if(!is.data.frame(x)) x <- as.data.frame(x)
  if(!is.vector(y)) y <- as.vector(y)
  n.var <- ncol(x)
  if(n.searched.var < 1 | n.searched.var > n.var)
    stop(message("Top n most important variables to be searched"),
         message("must at least be 1 and at most be ",
                 n.var, "!"))
  if(n.most.imp < 1 | n.most.imp > n.searched.var)
    stop(message("Initial n variables to be searched"),
         message("must at least be 1 and at most be ",
                 n.searched.var, "!"))
  set.mtry <- match.arg(set.mtry)
  if(set.mtry == "default"){
    mtry <- max(floor(n.var/3), 1)
    cat("Using default value of 'mtry' =", mtry, "\n")
  }
  else if(set.mtry == "tuned"){
    cat("Tuning random forest parameter 'mtry'. Please wait...\n")
    mtry <- randomForest::tuneRF(x, y, doBest = TRUE)$mtry
    cat("Best 'mtry' =", mtry, "\n")
  }
  else if(set.mtry == "complete"){
    mtry <- n.var
    cat("Using 'mtry' =", mtry, "\n")
  }
  suppressWarnings(require(foreach, quietly = TRUE, lib.loc = R.lib.loc))
  n.core <- parallel::detectCores()
  doParallel::registerDoParallel(cores = n.core)
  n.core <- getDoParWorkers()
  ntree <- vector("integer", 1L)
  cat("Growing", n.tree, "random decision trees using",
      n.core, "core(s)! Please wait...\n")
  RF <- foreach(ntree = rep(round(n.tree/n.core), n.core),
                .combine = randomForest::combine,
                .packages = 'randomForest') %dopar% {
                  randomForest(x, y, ntree = ntree, mtry = mtry,
                               importance = TRUE, nPerm = 10)
                }
  closeAllConnections()
  vim.type <- match.arg(vim.type)
  vim.type <- {
    if(vim.type == "rss") 2
    else if(vim.type == "mse") 1
  }
  RF.VIM <- sort(randomForest::importance(RF)[,vim.type],
                 decreasing = TRUE)
  cat(n.tree, "trees are grown and variable ranking by",
      "random forest is done!\n")
  X <- x[,names(RF.VIM)[1:n.searched.var]]
  doParallel::registerDoParallel(cores = n.core)
  SFFS1 <- sffs.svr(X[,1:n.most.imp], y, criterion = "mse",
                    kernel = kernel, kpar = kpar,
                    scaled = scaled, cost = cost, cv = cv)
  SFFS2 <- sffs.svr(X[,1:n.most.imp], y, criterion = "adjR2",
                    kernel = kernel, kpar = kpar,
                    scaled = scaled, cost = cost, cv = cv)
  first.selected.var <- intersect(SFFS1$selected.var,
                                  SFFS2$selected.var)
  first.selected.index <- intersect(SFFS1$var.index,
                                    SFFS2$var.index)
  if(length(first.selected.index) == 0)
    stop(message("Selection failure!"))
  first.mse <- fitness(X[,first.selected.index], y,
                       criterion = "mse",
                       kernel = kernel, kpar = kpar,
                       scaled = scaled, cost = cost, cv = cv)$value
  first.adjR2 <- fitness(X[,first.selected.index], y,
                         criterion = "adjR2",
                         kernel = kernel, kpar = kpar,
                         scaled = scaled, cost = cost, cv = cv)$value
  n <- length(first.selected.var)
  if(n.most.imp == n.searched.var &
     (n.searched.var == n.var |
      setequal(SFFS1$selected.var, SFFS2$selected.var) |
      (setequal(SFFS1$selected.var[1:n], first.selected.var) &
       setequal(SFFS2$selected.var[1:n], first.selected.var)))){
    first.selected <- rbind(first.selected.var,
                            first.selected.index)
    final.selected.var <-
      as.vector(gtools::mixedsort(first.selected[1,]))
    final.selected.index <-
      as.vector(first.selected[2,][gtools::mixedorder(first.selected[1,])])
    final.mse <- first.mse
    final.adjR2 <- first.adjR2
  }
  else{
    cat("\n")
    cat("Selected so far:", first.selected.var, "\n")
    cat("Mean squared error:", first.mse, "\n")
    cat("Adjusted R squared:", first.adjR2, "\n\n")
    SFFS3 <- sffs.svr(X, y, var.index = first.selected.index,
                      criterion = "mse", kernel = kernel, kpar = kpar,
                      scaled = scaled, cost = cost, cv = cv)
    SFFS4 <- sffs.svr(X, y, var.index = first.selected.index,
                      criterion = "adjR2", kernel = kernel, kpar = kpar,
                      scaled = scaled, cost = cost, cv = cv)
    final.selected.var <- intersect(SFFS3$selected.var,
                                    SFFS4$selected.var)
    final.selected.index <- intersect(SFFS3$var.index,
                                      SFFS4$var.index)
    final.mse <- fitness(X[,first.selected.index], y,
                         criterion = "mse",
                         kernel = kernel, kpar = kpar,
                         scaled = scaled, cost = cost, cv = cv)$value
    final.adjR2 <- fitness(X[,first.selected.index], y,
                           criterion = "adjR2",
                           kernel = kernel, kpar = kpar,
                           scaled = scaled, cost = cost, cv = cv)$value
    final.selected <- rbind(final.selected.var,
                            final.selected.index)
    final.selected.var <-
      as.vector(gtools::mixedsort(final.selected[1,]))
    final.selected.index <-
      as.vector(final.selected[2,][gtools::mixedorder(final.selected[1,])])
  }
  closeAllConnections()
  cat("\n", "Results:\n", sep = "")
  result <- print(data.frame(rbind(final.selected.var,
                                   final.selected.index),
                             row.names = c("Selected variables",
                                           "Rank (random forest)"),
                             fix.empty.names = FALSE))
  optimum <- print(data.frame(rbind(final.adjR2, final.mse),
                              row.names = c("Adjusted R squared:",
                                            "Mean squared error:"),
                              fix.empty.names = FALSE))
  end <- Sys.time()
  time.taken <- print(end - start)
  return(list(final.selected.var = final.selected.var,
              final.selected.index = final.selected.index,
              first.selected.var = first.selected.var,
              first.selected.index = first.selected.index,
              optimum = optimum, result = result, sorted.X = X,
              time.taken = time.taken))
}
##################################################################
# Main
# library("optparse")
#  
# option_list = list(
#     make_option(c("-s", "--snp"), type="character", default=NULL, 
#               help="SNPs dataset", metavar="character"),
#     make_option(c("-p", "--phenotype"), type="character", 
#               help="Phenotype measurement dataset", metavar="character")
#     make_option(c("-a", "--associd"), type="character", 
#               help="UUID of the two files", metavar="character")      
# ); 
#  
# opt_parser = OptionParser(option_list=option_list);
# opt = parse_args(opt_parser);

if(.Platform$OS.type == "windows"){
  R.lib.loc <- "C:/Users/lenovo/Documents/R/win-library/3.3"
  setwd("C:/Users/lenovo/Documents/SrdoFiles/spacio-project/resources/data"); #windows
}else if(.Platform$OS.type == "unix"){
  R.lib.loc <- "/home/user/R/lib/3.3"
  setwd("/home/user/htdocs/spacio-project/resources/data") 
}else{
  stop(message("Error: Unknown OS Type!"))
}

cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tPreparing data\n")
snps <- read.csv('snps_data.csv', header = FALSE, sep = ",")
phenotype <- read.csv('pheno_data.csv', header = FALSE, sep = ",")

cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tPreprocessing Data\n")
# Reformatting data
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tReformatting data\n")
snps.pos <- snps[(snps$V1 %in% c("chr", "pos")),]
snps.col <- snps[(snps$V1 %in% c("Type")),]
snps <- snps[!(snps$V1 %in% c("chr", "pos", "Type")),]
colnames(snps) <- unlist(snps.col[1,])
colnames(snps.pos) <- unlist(snps.col[1,])

phenotype.col <- phenotype[(phenotype$V1 %in% c("Type")),]
phenotype <- phenotype[!(phenotype$V1 %in% c("Type")),]
colnames(phenotype) <- unlist(phenotype.col[1,])

data <- cbind(snps, Phenotype=phenotype[,2])

# Removing missing values
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tRemoving missing values\n")
data.ms <- toNA(data, "--", 1, 2:ncol(snps), ncol(data))
data.type <- data.ms$type
data.geno <- data.ms$genotype
data.pheno <- data.ms$phenotype
ori.size <- dim(data.geno)

# Removing poor quality SNPs and Samples
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tRemoving poor quality data\n")
col.mcr <- 0.05 # Removing poor quality SNPs first.
row.mcr <- 0.05 # Followed by removing poor quality samples.
data.mcr <- mc.filter(data.geno, col.mcr, row.mcr)
data.geno <- data.mcr$genotype
if(!is.null(data.mcr$removed.rows)){
  data.pheno <- data.pheno[-data.mcr$removed.rows]
  data.type <- data.type[-data.mcr$removed.rows]
}
mcr.size <- dim(data.geno)

suppressWarnings(library("scrime", lib.loc = R.lib.loc)) # temporary ignore warning
# Recoding genotype values
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tRecoding genotype values\n")
data.geno <- scrime::recodeSNPs(data.geno, snp.in.col = TRUE)
# data.geno <- as.data.frame(data.geno)
# col.name <- names(data.geno)
# data.geno[,col.name] <- lapply(data.geno[,col.name],factor)

# Removing monomorphic SNPs
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tRemoving monomorphic sites\n")
data.mono <- scrime::identifyMonomorphism(t(data.geno))
if(length(data.mono) != 0)
  data.geno <- data.geno[,-data.mono]
poly.size <- dim(data.geno)

# Removing SNPs with Low MAF
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tRemoving SNPs with low MAF\n")
data.maf <- scrime::rowMAFs(t(data.geno))
maf <- 0.01 # SNPs with MAFs below this threshold are removed.
low.maf <- which(data.maf < maf)
if(length(low.maf != 0))
  data.geno <- data.geno[,-low.maf]
maf.size <- dim(data.geno)

# Imputing missing values
cat("--", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\tImputing missing genotype values\n")
data.geno <- scrime::knncatimpute(data.geno, "cohen", nn = 120)

# Summary
cat("##### Preprocessing Summary #####\n")
cat("*] Size of genotype matrix before pre-processing:", ori.size, "\n")
cat("*] Size of genotype matrix after call rate filter:", mcr.size, "\n")
cat("*] Size of genotype matrix after monomorphic filter:", poly.size, "\n")
cat("*] Size of genotype matrix after MAF filter:", maf.size, "\n")
cat("############################################################")

# Start the process
suppressWarnings(library("kernlab", lib.loc = R.lib.loc))
suppressWarnings(library("randomForest", lib.loc = R.lib.loc))
suppressWarnings(library("gtools", lib.loc = R.lib.loc))
suppressWarnings(library("doParallel", lib.loc = R.lib.loc))