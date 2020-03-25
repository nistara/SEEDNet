
quiet = function(x) { 
  sink(tempfile()) 
  on.exit(sink()) 
  invisible(force(x)) 
}

context("test commuting with network sample")
test_that("", {
    # g_file = "inst/sample_data/network/g_5.RDS"
    g_file = system.file("sample_data", "network", "g_5.RDS", package="SEEDNet")
    g = readRDS(g_file)
    comm_rate = 0.11
    g_edges = igraph::as_data_frame(g, "edges")
    g_verts = igraph::as_data_frame(g, "vertices")
    
    gc = quiet(disnet_commuting(g, N_c = comm_rate))
    gc_edges = igraph::as_data_frame(gc, "edges")
    gc_verts = igraph::as_data_frame(gc, "vertices")
    
    expect_that( nrow(gc_verts), equals(length(which(g_verts$pop >= 10))))
    # expect_that( z, is_a("character") )
    # expect_that( sum( is.na(z_acc)), equals(3) )
    
})


context("test commuting with generated sample")
test_that("", {
    
    g_file = system.file("sample_data", "network", "g_5.RDS", package="SEEDNet")
    g = readRDS(g_file)
    pop10 = igraph::V(g)[ igraph::V(g)$pop >= 10 ]
    g = igraph::induced.subgraph(g, pop10)
    g_edges = igraph::as_data_frame(g, "edges")
    g_verts = igraph::as_data_frame(g, "vertices")
    pop_from = dplyr::inner_join(g_edges, g_verts, by = c("from" = "name"))["pop"]
    g_edges$pop_from = pop_from$pop
    pop_to = dplyr::inner_join(g_edges, g_verts, by = c("to" = "name"))["pop"]
    g_edges$pop_to = pop_to$pop

    comm_rate = 0.11
    gc = quiet(disnet_commuting(g))
    gc_edges = igraph::as_data_frame(gc, "edges")
    gc_verts = igraph::as_data_frame(gc, "vertices")

    test_df = data.frame(from = c(33, 343, 890),
                         to = c(890, 33, 643))

    test_res = lapply(seq_len(nrow(test_df)), function(n, test_df, g, gc_edges) {
        from = test_df$from[n]
        to = test_df$to[n]
        
        m_i = g_verts$pop[ g_verts$name %in% from ]
        n_j = g_verts$pop[ g_verts$name %in% to ]
        dist = g_edges$Total_Length[ g_edges$from %in% from &
                                     g_edges$to %in% to]
        T_i = 0.11 # 142 OR 0.11 DEPENDING ON FORMULA 
        s_ij = sum(g_edges$pop_to[ g_edges$Total_Length <= dist &
                                   g_edges$from %in% from]) - n_j
        Tij = T_i * ( (m_i * n_j) / ((m_i + s_ij) * (m_i + n_j + s_ij)))
        gc_calc = gc_edges$commuting_prop[ gc_edges$from %in% from &
                                        gc_edges$to %in% to ]
        data.frame(Tij, gc_calc)

    }, test_df, g, gc_edges)

    test_res = do.call(rbind, test_res)

    expect_that( test_res$Tij, equals(test_res$gc_calc))
    
})



if(FALSE)
{
    
    test_that("Repeated root", {

        roots <- real.roots(1, 6000, 9000000)

        expect_that( length(roots), equals(1) )

        expect_that( roots, equals(-3000) )

        # Test whether ABSOLUTE error is within 0.1 
        expect_that( roots, equals(-3000.01, tolerance  = 0.1) )

        # Test whether RELATIVE error is within 0.1
        # To test relative error, set 'scale' equal to expected value.
        # See base R function all.equal for optional argument documentation.
        expect_equal( roots, -3001, tolerance  = 0.1, scale=-3001) 
    })


    test_that("Polynomial must be quadratic", {

        # Test for ANY error                     
        expect_that( real.roots(0, 2, 3), throws_error() )

        # Test specifically for an error string containing "zero"
        expect_that( real.roots(0, 2, 3), throws_error("zero") )

        # Test specifically for an error string containing "zero" or "Zero" using regular expression
        expect_that( real.roots(0, 2, 3), throws_error("[zZ]ero") )
    })


    test_that("Bogus tests", {

        x <- c(1, 2, 3)

        expect_that( length(x), equals(2.7) )
        expect_that( x, is_a("data.frame") )
    })

}
