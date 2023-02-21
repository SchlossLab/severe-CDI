library(tidyverse)
library(vegan)
library(readr)
library(ggplot2)
library(cowplot)
library(data.table)
library(here)
# alpha diversity
dat <- read_tsv("data/mothur/cdi.opti_mcc.groups.ave-std.summary") %>%
  filter(method == "ave") %>%
  select(group, sobs, shannon, invsimpson, coverage) %>%
  rename(sample_id = group) %>% 
  right_join(read_csv("data/process/cases_int_metadata.csv"), by = "sample_id") %>% 
  rename(Shannon=shannon, `Inverse Simpson`=invsimpson, `Number of OTUs`=sobs, IDSA=idsa, Allcause=allcause, Attrib=attrib)

alpha_plot <- dat %>% 
  select(sample_id, `Number of OTUs`, Shannon, `Inverse Simpson`, IDSA, Attrib, Allcause) %>%
  pivot_longer(c(IDSA, Attrib, Allcause), 
               names_to = "severity_metric", values_to = "is_severe") %>% 
  pivot_longer(c(`Number of OTUs`, Shannon, `Inverse Simpson`),
               names_to = "diversity_metric", values_to = "div_value") %>% 
  ggplot(aes(severity_metric, div_value, color = is_severe)) +
  geom_boxplot() +
  facet_wrap("diversity_metric", scales = 'free') +
  scale_color_manual(values=c(yes="#E41A1C", no="#377EB8"), name="is_severe") +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())

ggsave("figures/alpha_div.png", plot = alpha_plot)


# beta diversity
pc <- data.table::fread(here('data', 'mothur',
                             'cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.axes'))
case_data <- data.table::fread(here('data', 'process', 'cases_full_metadata.csv'))
names(pc)[names(pc) == "group"] <- "sample_id"
combined_df <- pc %>% inner_join(case_data, by=c('sample_id'))
idsa <- combined_df %>% 
  select("axis1", "axis2", "idsa") %>% 
  drop_na(idsa) %>% 
  rename(is_severe=idsa) %>% 
  mutate(outcome="IDSA")
attrib <- combined_df %>% 
  select("axis1", "axis2", "attrib") %>% 
  drop_na(attrib) %>% 
  rename(is_severe=attrib) %>% 
  mutate(outcome="Attrib")
allcause <- combined_df %>% 
  select("axis1", "axis2", "allcause") %>% 
  drop_na(allcause) %>% 
  rename(is_severe=allcause) %>% 
  mutate(outcome="Allcause")
all_outcomes <- bind_rows(allcause, attrib, idsa)
data.scores = as.data.frame(all_outcomes)
beta_plot <- data.scores %>% ggplot(aes(x=axis1, y=axis2, color = is_severe)) + 
  geom_point(alpha = 0.5) + facet_wrap("outcome", nrow = 1) + 
  theme_bw() + 
  scale_color_manual(values=c(yes="#E41A1C", no="#377EB8"), name="is_severe") + 
  theme(axis.title.x = element_blank(), axis.title.y = element_blank())

ggsave("figures/beta_div.png", plot = beta_plot)


combined_plot <- plot_grid(alpha_plot, beta_plot, labels = c('A', 'B'), ncol = 1)
ggsave("figures/alpha_and_beta_div.png", plot = combined_plot)