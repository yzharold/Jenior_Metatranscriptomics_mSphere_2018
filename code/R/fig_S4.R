
# Set up environment
rm(list=ls())
gc()

# Load in functions
starting_dir <- getwd()
source('~/Desktop/Repositories/Jenior_Metatranscriptomics_2016/code/R/functions.R')

# Define files
# Normalized Metatranscriptomes
noabx_normalized_reads <- 'data/read_mapping/conv_normalized_metaT.tsv'
cef_normalized_reads <- 'data/read_mapping/cef_normalized_metaT.tsv'
clinda_normalized_reads <- 'data/read_mapping/clinda_normalized_metaT.tsv'
strep_normalized_reads <- 'data/read_mapping/strep_normalized_metaT.tsv'

# Gene look up table
genes <- 'data/gene_names.tsv'

# Output plot
plot_file <- 'results/supplement/figures/figure_S5.pdf'

#--------------------------------------------------------------------------------------------------#

# Read in data
# Normalized Metatranscriptomes
noabx_normalized_reads <- read.delim(noabx_normalized_reads, sep='\t', header=TRUE, stringsAsFactors=FALSE)
cef_normalized_reads <- read.delim(cef_normalized_reads, sep='\t', header=TRUE, stringsAsFactors=FALSE)
clinda_normalized_reads <- read.delim(clinda_normalized_reads, sep='\t', header=TRUE, stringsAsFactors=FALSE)
strep_normalized_reads <- read.delim(strep_normalized_reads, sep='\t', header=TRUE, stringsAsFactors=FALSE)

# Gene functions
genes <- read.delim(genes, sep='\t', header=TRUE, stringsAsFactors=FALSE)

#--------------------------------------------------------------------------------------------------#

# Format data
# Remove excess columns
noabx_normalized_reads$ko <- NULL
cef_normalized_reads$ko <- NULL
clinda_normalized_reads$ko <- NULL
strep_normalized_reads$ko <- NULL

# Screen for those genes that have a gene annotation
noabx_annotated <- subset(noabx_normalized_reads, gene != '')
noabx_annotated <- noabx_annotated[!rownames(noabx_annotated) %in% rownames(noabx_annotated[grep('unknown_\\d', noabx_annotated$gene),]), ]
cef_annotated <- subset(cef_normalized_reads, gene != '')
cef_annotated <- cef_annotated[!rownames(cef_annotated) %in% rownames(cef_annotated[grep('unknown_\\d', cef_annotated$gene),]), ]
clinda_annotated <- subset(clinda_normalized_reads, gene != '')
clinda_annotated <- clinda_annotated[!rownames(clinda_annotated) %in% rownames(clinda_annotated[grep('unknown_\\d', clinda_annotated$gene),]), ]
strep_annotated <- subset(strep_normalized_reads, gene != '')
strep_annotated <- strep_annotated[!rownames(strep_annotated) %in% rownames(strep_annotated[grep('unknown_\\d', strep_annotated$gene),]), ]
rm(noabx_normalized_reads, cef_normalized_reads, clinda_normalized_reads, strep_normalized_reads)

# Screen out ribosomal genes
noabx_annotated <- rbind(subset(noabx_annotated, !grepl('rps*', noabx_annotated$gene)),
                         subset(noabx_annotated, !grepl('rpl*', noabx_annotated$gene)),
                         subset(noabx_annotated, !grepl('rpm*', noabx_annotated$gene)))

cef_annotated <- rbind(subset(cef_annotated, !grepl('rps.', cef_annotated$gene)),
                       subset(cef_annotated, !grepl('rpl.', cef_annotated$gene)))
clinda_annotated <- rbind(subset(clinda_annotated, !grepl('rps.', clinda_annotated$gene)),
                          subset(clinda_annotated, !grepl('rpl.', clinda_annotated$gene)))
strep_annotated <- rbind(subset(strep_annotated, !grepl('rps.', strep_annotated$gene)),
                         subset(strep_annotated, !grepl('rpl.', strep_annotated$gene)))

# Save pathway information
all_pathways <- rbind(noabx_annotated[,2:3],cef_annotated[,3:4],clinda_annotated[,3:4],strep_annotated[,3:4])
all_pathways <- all_pathways[!duplicated(all_pathways$gene), ]

# Reverse log2 transformation temporarily
noabx_annotated$conv_metaT_reads <- 2 ^ noabx_annotated$conv_metaT_reads
cef_annotated$cef_630_metaT_reads <- 2 ^ cef_annotated$cef_630_metaT_reads
cef_annotated$cef_mock_metaT_reads <- 2 ^ cef_annotated$cef_mock_metaT_reads
clinda_annotated$clinda_630_metaT_reads <- 2 ^ clinda_annotated$clinda_630_metaT_reads
clinda_annotated$clinda_mock_metaT_reads <- 2 ^ clinda_annotated$clinda_mock_metaT_reads
strep_annotated$strep_630_metaT_reads <- 2 ^ strep_annotated$strep_630_metaT_reads
strep_annotated$strep_mock_metaT_reads <- 2 ^ strep_annotated$strep_mock_metaT_reads

# Subset to treatment groups
noabx_annotated$conv_metaT_reads <- as.numeric(noabx_annotated$conv_metaT_reads)
cef_630_annotated <- cef_annotated
cef_630_annotated$cef_630_metaT_reads <- as.numeric(cef_630_annotated$cef_630_metaT_reads)
cef_630_annotated$cef_mock_metaT_reads <- NULL
cef_mock_annotated <- cef_annotated
cef_mock_annotated$cef_mock_metaT_reads <- as.numeric(cef_mock_annotated$cef_mock_metaT_reads)
cef_mock_annotated$cef_630_metaT_reads <- NULL
clinda_630_annotated <- clinda_annotated
clinda_630_annotated$clinda_630_metaT_reads <- as.numeric(clinda_630_annotated$clinda_630_metaT_reads)
clinda_630_annotated$clinda_mock_metaT_reads <- NULL
clinda_mock_annotated <- clinda_annotated
clinda_mock_annotated$clinda_mock_metaT_reads <- as.numeric(clinda_mock_annotated$clinda_mock_metaT_reads)
clinda_mock_annotated$clinda_630_metaT_reads <- NULL
strep_630_annotated <- strep_annotated
strep_630_annotated$strep_630_metaT_reads <- as.numeric(strep_630_annotated$strep_630_metaT_reads)
strep_630_annotated$strep_mock_metaT_reads <- NULL
strep_mock_annotated <- strep_annotated
strep_mock_annotated$strep_mock_metaT_reads <- as.numeric(strep_mock_annotated$strep_mock_metaT_reads)
strep_mock_annotated$strep_630_metaT_reads <- NULL
rm(cef_annotated, clinda_annotated, strep_annotated)

# Aggregate identical genes, regardless of organism - retransform
noabx_annotated <- aggregate(noabx_annotated$conv_metaT_reads, by=list(noabx_annotated$gene), FUN=sum)
colnames(noabx_annotated) <- c('gene', 'noabx_reads')
cef_630_annotated <- aggregate(cef_630_annotated$cef_630_metaT_reads, by=list(cef_630_annotated$gene), FUN=sum)
colnames(cef_630_annotated) <- c('gene', 'cef_630_reads')
cef_mock_annotated <- aggregate(cef_mock_annotated$cef_mock_metaT_reads, by=list(cef_mock_annotated$gene), FUN=sum)
colnames(cef_mock_annotated) <- c('gene', 'cef_mock_reads')
clinda_630_annotated <- aggregate(clinda_630_annotated$clinda_630_metaT_reads, by=list(clinda_630_annotated$gene), FUN=sum)
colnames(clinda_630_annotated) <- c('gene', 'clinda_630_reads')
clinda_mock_annotated <- aggregate(clinda_mock_annotated$clinda_mock_metaT_reads, by=list(clinda_mock_annotated$gene), FUN=sum)
colnames(clinda_mock_annotated) <- c('gene', 'clinda_mock_reads')
strep_630_annotated <- aggregate(strep_630_annotated$strep_630_metaT_reads, by=list(strep_630_annotated$gene), FUN=sum)
colnames(strep_630_annotated) <- c('gene', 'strep_630_reads')
strep_mock_annotated <- aggregate(strep_mock_annotated$strep_mock_metaT_reads, by=list(strep_mock_annotated$gene), FUN=sum)
colnames(strep_mock_annotated) <- c('gene', 'strep_mock_reads')

#--------------------------------------------------------------------------------------------------#

# Combine each with no antibiotic controls
cef_630_annotated <- merge(cef_630_annotated, noabx_annotated, by='gene')
cef_mock_annotated <- merge(cef_mock_annotated, noabx_annotated, by='gene')
clinda_630_annotated <- merge(clinda_630_annotated, noabx_annotated, by='gene')
clinda_mock_annotated <- merge(clinda_mock_annotated, noabx_annotated, by='gene')
strep_630_annotated <- merge(strep_630_annotated, noabx_annotated, by='gene')
strep_mock_annotated <- merge(strep_mock_annotated, noabx_annotated, by='gene')
rm(noabx_annotated)

# Calculate differences in expression and remove those with no change
cef_630_annotated$difference <- abs(cef_630_annotated$cef_630_reads - cef_630_annotated$noabx_reads)
cef_630_annotated <- subset(cef_630_annotated, difference > 0)
cef_mock_annotated$difference <- abs(cef_mock_annotated$cef_mock_reads - cef_mock_annotated$noabx_reads)
cef_mock_annotated <- subset(cef_mock_annotated, difference > 0)
clinda_630_annotated$difference <- abs(clinda_630_annotated$clinda_630_reads - clinda_630_annotated$noabx_reads)
clinda_630_annotated <- subset(clinda_630_annotated, difference > 0)
clinda_mock_annotated$difference <- abs(clinda_mock_annotated$clinda_mock_reads - clinda_mock_annotated$noabx_reads)
clinda_mock_annotated <- subset(clinda_mock_annotated, difference > 0)
strep_630_annotated$difference <- abs(strep_630_annotated$strep_630_reads - strep_630_annotated$noabx_reads)
strep_630_annotated <- subset(strep_630_annotated, difference > 0)
strep_mock_annotated$difference <- abs(strep_mock_annotated$strep_mock_reads - strep_mock_annotated$noabx_reads)
strep_mock_annotated <- subset(strep_mock_annotated, difference > 0)

# Rank differences and subset to top 15
cef_630_annotated <- cef_630_annotated[order(-cef_630_annotated$difference),]
cef_630_annotated$difference <- NULL
cef_630_top <- cef_630_annotated[1:15,]
cef_mock_annotated <- cef_mock_annotated[order(-cef_mock_annotated$difference),]
cef_mock_annotated$difference <- NULL
cef_mock_top <- cef_mock_annotated[1:15,]
clinda_630_annotated <- clinda_630_annotated[order(-clinda_630_annotated$difference),]
clinda_630_annotated$difference <- NULL
clinda_630_top <- clinda_630_annotated[1:15,]
clinda_mock_annotated <- clinda_mock_annotated[order(-clinda_mock_annotated$difference),]
clinda_mock_annotated$difference <- NULL
clinda_mock_top <- clinda_mock_annotated[1:15,]
strep_630_annotated <- strep_630_annotated[order(-strep_630_annotated$difference),]
strep_630_annotated$difference <- NULL
strep_630_top <- strep_630_annotated[1:15,]
strep_mock_annotated <- strep_mock_annotated[order(-strep_mock_annotated$difference),]
strep_mock_annotated$difference <- NULL
strep_mock_top <- strep_mock_annotated[1:15,]
rm(cef_630_annotated,cef_mock_annotated,clinda_630_annotated,
   clinda_mock_annotated,strep_630_annotated,strep_mock_annotated)

# Log transform expression
cef_630_top[,2:3] <- log2(cef_630_top[,2:3] + 1)
cef_mock_top[,2:3] <- log2(cef_mock_top[,2:3] + 1)
clinda_630_top[,2:3] <- log2(clinda_630_top[,2:3] + 1)
clinda_mock_top[,2:3] <- log2(clinda_mock_top[,2:3] + 1)
strep_630_top[,2:3] <- log2(strep_630_top[,2:3] + 1)
strep_mock_top[,2:3] <- log2(strep_mock_top[,2:3] + 1)

# Reassociate with pathway annotations
cef_630_top_pathways <- merge(cef_630_top, all_pathways, by='gene', all.x=TRUE)
cef_mock_top_pathways <- merge(cef_mock_top, all_pathways, by='gene', all.x=TRUE)
clinda_630_top_pathways <- merge(clinda_630_top, all_pathways, by='gene', all.x=TRUE)
clinda_mock_top_pathways <- merge(clinda_mock_top, all_pathways, by='gene', all.x=TRUE)
strep_630_top_pathways <- merge(strep_630_top, all_pathways, by='gene', all.x=TRUE)
strep_mock_top_pathways <- merge(strep_mock_top, all_pathways, by='gene', all.x=TRUE)
rm(all_pathways)

# Add rownames
cef_630_top <- merge(cef_630_top, genes, by='gene', all.x=TRUE)
cef_630_top$gene <- NULL
cef_630_top$name <- gsub('_', ' ', cef_630_top$name)
rownames(cef_630_top) <- cef_630_top$name
cef_630_top$name <- NULL
cef_mock_top <- merge(cef_mock_top, genes, by='gene', all.x=TRUE)
cef_mock_top$gene <- NULL
cef_mock_top$name <- gsub('_', ' ', cef_mock_top$name)
rownames(cef_mock_top) <- cef_mock_top$name
cef_mock_top$name <- NULL
clinda_630_top <- merge(clinda_630_top, genes, by='gene', all.x=TRUE)
clinda_630_top$gene <- NULL
clinda_630_top$name <- gsub('_', ' ', clinda_630_top$name)
rownames(clinda_630_top) <- clinda_630_top$name
clinda_630_top$name <- NULL
clinda_mock_top <- merge(clinda_mock_top, genes, by='gene', all.x=TRUE)
clinda_mock_top$gene <- NULL
clinda_mock_top$name <- gsub('_', ' ', clinda_mock_top$name)
rownames(clinda_mock_top) <- clinda_mock_top$name
clinda_mock_top$name <- NULL
strep_630_top <- merge(strep_630_top, genes, by='gene', all.x=TRUE)
strep_630_top$gene <- NULL
strep_630_top$name <- gsub('_', ' ', strep_630_top$name)
rownames(strep_630_top) <- strep_630_top$name
strep_630_top$name <- NULL
strep_mock_top <- merge(strep_mock_top, genes, by='gene', all.x=TRUE)
strep_mock_top$gene <- NULL
strep_mock_top$name <- gsub('_', ' ', strep_mock_top$name)
rownames(strep_mock_top) <- strep_mock_top$name
strep_mock_top$name <- NULL
rm(genes)

# Reorder by expression in treatment group
cef_630_top <- cef_630_top[order(cef_630_top$cef_630_reads),]
cef_mock_top <- cef_mock_top[order(cef_mock_top$cef_mock_reads),]
clinda_630_top <- clinda_630_top[order(clinda_630_top$clinda_630_reads),]
clinda_mock_top <- clinda_mock_top[order(clinda_mock_top$clinda_mock_reads),]
strep_630_top <- strep_630_top[order(strep_630_top$strep_630_reads),]
strep_mock_top <- strep_mock_top[order(strep_mock_top$strep_mock_reads),]

# Convert to matrices for barplots
cef_630_top <- as.matrix(t(cef_630_top))
cef_mock_top <- as.matrix(t(cef_mock_top))
clinda_630_top <- as.matrix(t(clinda_630_top))
clinda_mock_top <- as.matrix(t(clinda_mock_top))
strep_630_top <- as.matrix(t(strep_630_top))
strep_mock_top <- as.matrix(t(strep_mock_top))

# Reverse the row order so infected plots first
cef_630_top <- cef_630_top[rev(rownames(cef_630_top)),]
cef_mock_top <- cef_mock_top[rev(rownames(cef_mock_top)),]
clinda_630_top <- clinda_630_top[rev(rownames(clinda_630_top)),]
clinda_mock_top <- clinda_mock_top[rev(rownames(clinda_mock_top)),]
strep_630_top <- strep_630_top[rev(rownames(strep_630_top)),]
strep_mock_top <- strep_mock_top[rev(rownames(strep_mock_top)),]

#--------------------------------------------------------------------------------------------------#

# Generate figure
pdf(file=plot_file, width=11, height=12)
layout(matrix(c(1,1,2,2,3,
                4,4,5,5,6,
                7,7,8,8,9),
              nrow=3, ncol=5, byrow = TRUE))

#------------------#

# Streptomycin
# Mock-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(strep_mock_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE, 
        xlab='', ylab='', col=c(noabx_col, strep_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext('Mock-infected', side=3, padj=-0.3, cex=0.9)
mtext('A', side=2, padj=-11, adj=18, cex=1.2, font=2)

# 630-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(strep_630_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE,
        xlab='', ylab='', col=c(noabx_col, strep_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext(expression(paste(italic('C. difficile'),' 630-infected')), side=3, padj=-0.3, cex=0.9)
mtext('B', side=2, padj=-11, adj=17, cex=1.2, font=2)

# Legend
par(mar=c(0,0,0,1))
plot(0, type='n', axes=FALSE, xlab='', ylab='', xlim=c(-5,5), ylim=c(-10,10))
legend('center', legend=c('Streptomycin-pretreated','No Antibiotics (No CDI)'), pt.bg=c(strep_col,noabx_col), 
       pch=22, pt.cex=2.4, cex=1.3)

#------------------#

# Cefoperazone
# Mock-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(cef_mock_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE, 
        xlab='', ylab='', col=c(noabx_col, cef_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext('Mock-infected', side=3, padj=-0.3, cex=0.9)
mtext('C', side=2, padj=-11, adj=18, cex=1.2, font=2)

# 630-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(cef_630_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE, 
        xlab='', ylab='', col=c(noabx_col, cef_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext(expression(paste(italic('C. difficile'),' 630-infected')), side=3, padj=-0.3, cex=0.9)
mtext('D', side=2, padj=-11, adj=17, cex=1.2, font=2)

# Legend
par(mar=c(0,0,0,1))
plot(0, type='n', axes=FALSE, xlab='', ylab='', xlim=c(-5,5), ylim=c(-10,10))
legend('center', legend=c('Cefoperazone-pretreated','No Antibiotics (No CDI)'), pt.bg=c(cef_col,noabx_col), 
       pch=22, pt.cex=2.4, cex=1.3)

#------------------#

# Clindamycin
# Mock-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(clinda_mock_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE, 
        xlab='', ylab='', col=c(noabx_col, clinda_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext('Mock-infected', side=3, padj=-0.3, cex=0.9)
mtext('E', side=2, padj=-11, adj=18, cex=1.2, font=2)

# 630-infected
par(mar=c(4,16,3,1), mgp=c(2.5, 0.75, 0), las=1, xaxs='i')
barplot(clinda_630_top, xaxt='n', xlim=c(0,14), beside=TRUE, horiz=TRUE, 
        xlab='', ylab='', col=c(noabx_col, clinda_col), cex.names=1) 
box()
axis(1, at=seq(0,14,2), label=seq(0,14,2))
minor.ticks.axis(1, 10, mn=0, mx=14)
mtext(expression(paste('Metagenome-normalized cDNA Reads (',log[2],')')), side=1, padj=2.5, cex=0.8)
mtext(expression(paste(italic('C. difficile'),' 630-infected')), side=3, padj=-0.3, cex=0.9)
mtext('F', side=2, padj=-11, adj=30, cex=1.2, font=2)

# Legend
par(mar=c(0,0,0,1))
plot(0, type='n', axes=FALSE, xlab='', ylab='', xlim=c(-5,5), ylim=c(-10,10))
legend('center', legend=c('Clindamycin-pretreated','No Antibiotics (No CDI)'), pt.bg=c(clinda_col,noabx_col), 
       pch=22, pt.cex=2.4, cex=1.3)

dev.off()

#--------------------------------------------------------------------------------------------------#

#Clean up
for (dep in deps){
  pkg <- paste('package:', dep, sep='')
  detach(pkg, character.only = TRUE)
}
setwd(starting_dir)
rm(list=ls())
gc()
