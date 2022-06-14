library(tidyverse)

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
  scale_color_brewer(palette = 'Dark2') +
  theme_bw() +
  theme(axis.title.x = element_blank(),
        axis.title.y = element_blank())

ggsave("figures/alpha_div.png", plot = alpha_plot)