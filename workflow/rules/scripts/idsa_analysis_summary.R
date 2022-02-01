source("workflow/rules/scripts/utilities.R") #Loads libraries, reads in metadata, functions

a <- ggdraw() + draw_image("results/figures/idsa_severe_n.png")
b <- ggdraw() + draw_image("results/figures/idsa_alpha_inv_simpson.png")
c <- ggdraw() + draw_image("results/figures/ml_performance_idsa_otu.png")
d <- ggdraw() + draw_image("results/figures/ml_performance_idsa_otu_AUC.png")
e <- ggdraw() + draw_image("results/figures/feat_imp_rf_idsa_severity.png")
f <- ggdraw() + draw_image("results/figures/feat_imp_idsa_severe_otus_abund.png")

plot_grid(a, b, c, d, e, f, labels = c("A", "B", "C" ,"D", "E", "F"), label_size = 12, ncol=2)+
  ggsave("results/figures/severe_idsa_summary.pdf", width=7, height=10)
