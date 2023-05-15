library(cowplot)
library(ggsankey)
library(glue)
library(knitr)
library(schtools)
library(tidyverse)
library(yaml)

metadat_cases <- read_csv('data/process/cases_full_metadata.csv') %>% 
  filter(!(is.na(idsa) & is.na(allcause) & is.na(attrib) & is.na(pragmatic)))
metadat_cases_sankey <- metadat_cases %>%
  mutate(
    IDSA = if_else(is.na(idsa), 'missing_data', idsa),
    `All-cause` = if_else(is.na(allcause), 'missing_data', allcause),
    Attrib = if_else(is.na(attrib), 'missing_data', attrib),
    Pragmatic = if_else(is.na(pragmatic), 'missing_data', pragmatic)
  )
plot_sankey <- function(dat_long) {
  dat_long %>%
    rename(is_severe = node,
           severity_definition = x) %>%
    left_join(
      metadat_cases_sankey %>%
        pivot_longer(
          c(IDSA, `All-cause`, Attrib, Pragmatic),
          names_to = 'severity_definition',
          values_to = 'is_severe'
        ) %>%
        count(severity_definition, is_severe),
      by = c('severity_definition', 'is_severe')
    ) %>% 
    mutate(severity_definition = factor(severity_definition,
                                        levels = c('IDSA', 'All-cause', 'Attrib', 'Pragmatic'))) %>%
    ggplot(aes(
      x = severity_definition,
      next_x = next_x,
      node = is_severe,
      next_node = next_node,
      fill = is_severe,
      label = n
    )) +
    geom_sankey(flow.alpha = .6) +
    geom_sankey_label(color = 'white', show.legend = FALSE) +
    scale_fill_manual(values = c(yes="#860967", no="#0F2A4B", 
                                 'missing_data'="#BDBDBD")) +
    labs(x = 'Severity Definition') +
    theme_sankey() +
    theme(text = element_text(size = 10, family = "Helvetica"))
}
sankey <- metadat_cases_sankey %>%
  make_long(c(IDSA, `All-cause`, Attrib, Pragmatic)) %>%
  plot_sankey()
flowchart <- ggdraw() + draw_image('figures/severity_flowchart.tiff')
fig <- plot_grid(flowchart, sankey, 
          nrow = 2, rel_heights = c(1, 0.5),
          labels = 'AUTO')
ggsave('figures/flowchart_sankey.tiff', plot = fig,
       device = 'tiff', bg = 'white',
       width = 6.8, height = 7.5)

