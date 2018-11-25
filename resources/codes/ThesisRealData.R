##################################################################
#                  RICE SNP DATA PRE-PROCESSING                  #
#                    Dani Setiawan G651150281                    #
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
cat("Uploading data.\n")
setwd("C:/Users/lenovo/Downloads/Documents/[Penelitian Dani]/Data")
padi <- read.csv("dataFull.csv", header = FALSE, sep = ",")
position <- read.csv("posisi.csv", header = TRUE, sep = ",")
SNP.col <- paste('SNP', 1:1536, sep = "")
pheno.col <- paste('Pheno', 1:12, sep = "")
colnames(padi) <- c('Type', SNP.col, pheno.col)

cat("Changing missing symbol to NA.\n")
padi.ms <- toNA(padi, "--", 1, 2:1537, 1538:1549)
padi.type <- padi.ms$type
padi.geno <- padi.ms$genotype
padi.pheno <- padi.ms$phenotype

cat("Arranging SNPs based on position.\n")
padi.geno <- cbind(position, t(padi.geno))
padi.geno <- padi.geno[order(padi.geno[,1], padi.geno[,2]),]
padi.geno <- t(padi.geno[,3:ncol(padi.geno)])
ori.size <- dim(padi.geno)

cat("Removing poor quality SNPs and samples.\n")
col.mcr <- 0.05 # Removing poor quality SNPs first.
row.mcr <- 0.05 # Followed by removing poor quality samples.
padi.mcr <- mc.filter(padi.geno, col.mcr, row.mcr)
padi.geno <- padi.mcr$genotype
if(!is.null(padi.mcr$removed.rows)){
  padi.pheno <- padi.pheno[-padi.mcr$removed.rows,]
  padi.type <- padi.type[-padi.mcr$removed.rows]
}
mcr.size <- dim(padi.geno)

cat("Recoding SNPs.\n")
padi.geno <- scrime::recodeSNPs(padi.geno, snp.in.col = TRUE)

cat("Removing monomorphic SNPs.\n")
padi.mono <- scrime::identifyMonomorphism(t(padi.geno))
if(length(padi.mono) != 0)
  padi.geno <- padi.geno[,-padi.mono]
poly.size <- dim(padi.geno)

cat("Removing SNPs with low MAFs.\n")
padi.maf <- scrime::rowMAFs(t(padi.geno))
maf <- 0.01 # SNPs with MAFs below this threshold are removed.
low.maf <- which(padi.maf < maf)
if(length(low.maf != 0))
  padi.geno <- padi.geno[,-low.maf]
maf.size <- dim(padi.geno)

#cat("Checking Hardy-Weinberg equilibrium.\n")
#padi.hwe <- scrime::rowHWEs(t(padi.geno))
#rawp <- 1e-3 # SNPs with p-values below this threshold are removed.
#padi.hwd <- which(padi.hwe$rawp < rawp)
#if(length(padi.hwd) != 0)
#  padi.geno <- padi.geno[,-padi.hwd]
#hwe.size <- dim(padi.geno)

cat("Imputing missing values using k nearest observations.\n")
padi.geno <- scrime::knncatimpute(padi.geno, "cohen", nn = 120)

cat("Size of genotype matrix before pre-processing:\n")
ori.size
cat("Size of genotype matrix after call rate filter:\n")
mcr.size
cat("Size of genotype matrix after monomorphic filter:\n")
poly.size
cat("Size of genotype matrix after MAF filter:\n")
maf.size
#cat("Size of genotype matrix after HWE filter:\n")
#hwe.size
##################################################################
select.padi <- select(padi.geno, padi.pheno[,1],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,2],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,3],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,4],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,5],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,6],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,7],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,8],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,9],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,10],
                      set.mtry = "complete")
select.padi <- select(padi.geno, padi.pheno[,11],
                      set.mtry = "complete")
##################################################################