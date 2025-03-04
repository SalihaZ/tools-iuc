#!/usr/bin/env R
VERSION <- "0.2" # nolint

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1) {
     message(paste("VERSION:", VERSION))
     stop("Please provide the config file")
}

suppressWarnings(suppressPackageStartupMessages(require(RaceID)))
suppressWarnings(suppressPackageStartupMessages(require(FateID)))
source(args[1])

test <- list()
test$side <- 3
test$line <- 2.5
second <- test
second$cex <- 0.5
second$line <- 2.5

do.trajectoryinspection.stemid <- function(ltr) { # nolint
    makeBranchLink <- function(i, j, k) { # nolint
        ingoing <- paste(sort(c(i, j)), collapse = ".")
        outgoing <- paste(sort(c(j, k)), collapse = ".")
        messed <- sort(c(ingoing, outgoing))
        return(list(messed[[1]], messed[[2]]))
    }

    zzz <- do.call(getproj, c(ltr, trjsid.getproj))
    bra <- branchcells(
        ltr,
        do.call("makeBranchLink", as.list(trjsid.branchcells.ijk))
    )
    write.table(
        head(bra$diffgenes$z, trjsid.numdiffgenes),
        file = out.diffgenes)

    par(mfrow = c(3, 2), cex = 0.5)
    print(do.call(plotmap, c(bra$scl, final = FALSE, fr = FALSE)))
    print(do.call(mtext, c("Initial Clusters (tSNE)", test)))
    print(do.call(plotmap, c(bra$scl, final = TRUE, fr = FALSE)))
    print(do.call(mtext, c("Final Clusters (tSNE)", test)))
    print(do.call(plotmap, c(bra$scl, final = FALSE, um = TRUE)))
    print(do.call(mtext, c("Initial Clusters (UMAP)", test)))
    print(do.call(plotmap, c(bra$scl, final = TRUE, um = TRUE)))
    print(do.call(mtext, c("Final Clusters (UMAP)", test)))
    print(do.call(plotmap, c(bra$scl, final = FALSE, fr = TRUE)))
    print(do.call(mtext, c("Initial Clusters (F-R)", test)))
    print(do.call(plotmap, c(bra$scl, final = TRUE, fr = TRUE)))
    print(do.call(mtext, c("Final Clusters (F-R)", test)))
}

do.trajectoryinspection.fateid <- function(ltr) { # nolint
    n <- do.call(cellsfromtree, c(ltr, trjfid_cellsfrom))
    x <- getfdata(ltr@sc)

    trjfid_filterset$x <- x
    trjfid_filterset$n <- n$f
    fs <- do.call(filterset, c(trjfid_filterset))
    trjfid_getsom$x <- fs
    s1d <- do.call(getsom, c(trjfid_getsom))
    trjfid_procsom$s1d <- s1d
    ps <- do.call(procsom, c(trjfid_procsom))

    y    <- ltr@sc@cpart[n$f]
    fcol <- ltr@sc@fcol

    trjfid_plotheat$xpart <- y
    trjfid_plotheat$xcol <- fcol

    test$side <- 3
    test$line <- 3

    ##Plot average z-score for all modules derived from the SOM:
    trjfid_plotheat$x <- ps$nodes.z
    trjfid_plotheat$ypart <- unique(ps$nodes)
    print(do.call(plotheatmap, c(trjfid_plotheat)))
    print(do.call(mtext, c("Average z-score for all modules derived from SOM",
                           test)))
    ##Plot z-score profile of each gene ordered by SOM modules:
    trjfid_plotheat$x <- ps$all.z
    trjfid_plotheat$ypart <- ps$nodes
    print(do.call(plotheatmap, c(trjfid_plotheat)))
    print(do.call(mtext, c(paste0("z-score profile of each gene",
                                  "ordered by SOM modules"), test)))
    ##Plot normalized expression profile of each gene ordered by SOM modules:
    trjfid_plotheat$x <- ps$all.e
    trjfid_plotheat$ypart <- ps$nodes
    print(do.call(plotheatmap, c(trjfid_plotheat)))
    print(do.call(mtext, c(paste0("Normalized expression profile of each",
                                  "gene ordered by SOM modules"), test)))
    ##Plot binarized expression profile of each gene
    ##(z-score < -1, -1 < z-score < 1, z-score > 1)
    trjfid_plotheat$x <- ps$all.b
    trjfid_plotheat$ypart <- ps$nodes
    print(do.call(plotheatmap, c(trjfid_plotheat)))
    print(do.call(mtext, c("Binarized expression profile of each gene", test)))
    ## This should be written out, and passed back into the tool
    ## to perform sominspect
    return(list(fs = fs, ps = ps, y = y, fcol = fcol, nf = n$f))
}

do.trajectoryinspection.fateid.sominspect <- function(domo) { # nolint
    g <- trjfidsomi.use.genes
    if (class(g) == "numeric") {
        g <- names(ps$nodes)[ps$nodes %in% g]
    }

    typ <- NULL
    if (!is.null(trjfidsomi.use.types)) {
        typ <- sub(trjfidsomi.use.types, "", domo$nf)
    }

    trjfidsomi$x <- domo$fs
    trjfidsomi$y <- domo$y
    trjfidsomi$g <- g
    trjfidsomi$n <- domo$nf
    trjfidsomi$col <- domo$fcol
    trjfidsomi$types <- typ

    ## The average pseudo-temporal expression profile of this group
    ## can be plotted by the function plotexpression:
    par(mfrow = c(1, 1))
    test$cex <- 1
    second$line <- 1.5
    if (trjfidsomi$name == "Title") trjfidsomi$name <- ""
    print(do.call(plotexpression, c(trjfidsomi)))
    mess2 <- paste(c(trjfidsomi.use.genes), collapse = ", ")
    mess1 <- "Average pseudo-temporal expression profile"
    print(do.call(mtext, c(mess1, test)))
    print(do.call(mtext, c(mess2, second)))
}

ltr <- in.rdat

pdf(out.pdf)
if (perform.stemid) do.trajectoryinspection.stemid(ltr)
if (perform.fateid) {
    domo <- do.trajectoryinspection.fateid(ltr)
    if (perform.fateid.sominspect) {
        do.trajectoryinspection.fateid.sominspect(domo)
    }
}
dev.off()
