library(tidyverse)
library(vegan)
library(readr)
library(ggplot2)
library(ggpubr)
library(data.table)
library(here)
# alpha diversity
dat <- read_tsv("data/mothur/cdi.opti_mcc.groups.ave-std.summary") %>%
  filter(method == "ave") %>%
  select(group, sobs, shannon, invsimpson, coverage) %>%
  rename(sample_id = group) %>% 
  right_join(read_csv("data/process/cases_int_metadata.csv"), by = "sample_id")

alpha_plot <- dat %>% 
  select(sample_id, sobs, shannon, invsimpson, idsa, attrib, allcause) %>%
  pivot_longer(c(idsa, attrib, allcause), 
               names_to = "severity_metric", values_to = "is_severe") %>% 
  pivot_longer(c(sobs, shannon, invsimpson),
               names_to = "diversity_metric", values_to = "div_value") %>% 
  ggplot(aes(severity_metric, div_value, color = is_severe)) +
  geom_boxplot() +
  facet_wrap("diversity_metric", scales = 'free') +
  scale_color_brewer(palette = 'Set1') +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())

ggsave("figures/alpha_div.png", plot = alpha_plot)


# beta diversity
pc <- data.table::fread(here('data', 'mothur',
                             'cdi.opti_mcc.braycurtis.0.03.lt.ave.nmds.axes'))
case_data <- data.table::fread(here('data', 'process',
                                    'cases_full_metadata.csv'))
names(pc)[names(pc) == "group"] <- "sample_id"
pc
combined_df <- pc %>% inner_join( case_data, 
                                  by=c('sample_id'))
idsa <- combined_df %>% select("axis1", "axis2", "idsa") %>% drop_na(idsa)
attrib <- combined_df %>% select("axis1", "axis2", "attrib") %>% drop_na(attrib)
allcause <- combined_df %>% select("axis1", "axis2", "allcause") %>% drop_na(allcause)
data.scores = as.data.frame(idsa)
idsa_plot <- ggplot(data.scores, aes(x = axis1, y = axis2)) + 
  geom_point(aes(color = idsa)) + ggtitle("idsa") + 
  theme_bw() + 
  theme(legend.position = "none", axis.title.x = element_blank(), axis.title.y = element_blank(), plot.title = element_text(hjust = 0.5)) + 
  scale_color_brewer(palette="Set1")
data.scores = as.data.frame(attrib)
attrib_plot <- ggplot(data.scores, aes(x = axis1, y = axis2)) + 
  geom_point(aes(color = attrib)) + 
  ggtitle("attrib") + 
  theme_bw() + 
  theme(legend.position = "none", axis.title.x = element_blank(), axis.title.y = element_blank(), plot.title = element_text(hjust = 0.5)) +
  scale_color_brewer(palette="Set1")
data.scores = as.data.frame(allcause)
allcause_plot <- ggplot(data.scores, aes(x = axis1, y = axis2)) + 
  geom_point(aes(color = allcause)) + 
  ggtitle("allcause") + 
  theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5), axis.title.x = element_blank(), axis.title.y = element_blank()) +
  scale_color_brewer(palette="Set1", name="is_severe")
beta_plot <- ggarrange(idsa_plot, attrib_plot, allcause_plot, nrow = 1, widths = c(6, 6, 9))

ggsave("figures/beta_div.png", plot = beta_plot)


combined_plot <- ggarrange(alpha_plot, beta_plot, nrow = 2)
ggsave("figures/alpha_and_beta_div.png", plot = combined_plot)