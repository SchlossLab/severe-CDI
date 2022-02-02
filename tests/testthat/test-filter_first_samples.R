library(tidyverse)
source(here('workflow', 'rules', 'scripts', 'filter_first_samples.R'))

test_df <- tibble(patient_id = c('a', 'b', 'b', 'c', 'c', 'c'),
                      collection_date = c("2019-01-01", "2019-02-03", "2017-03-09", "2016-01-10", "2016-01-10", "2020-03-11"),
                      sample_id = 1:6)

filt_df <- tibble(patient_id = c('a', 'b', 'c'),
                      collection_date = c("2019-01-01", "2017-03-09", "2016-01-10"),
                      sample_id = c(1, 3, 4)) 

test_that("filter_first_samples() works", {
  expect_equal(filter_first_samples(test_df), filt_df)
  expect_equal(filter_first_samples(tibble(patient_id = c('a', 'b'),
                                           collection_date = c("2019-01-01", "2019-02-03"),
                                           sample_id = 1:2)), 
                                    tibble(patient_id = c('a', 'b'),
                                           collection_date = c("2019-01-01", "2019-02-03"),
                                           sample_id = 1:2)
               )
  expect_equal(filter_first_samples(tibble(patient_id = c('a', 'a'),
                                           collection_date = c("2019-01-01", "2019-02-03"),
                                           sample_id = 1:2)), 
                                    tibble(patient_id = c('a'),
                                           collection_date = c("2019-01-01"),
                                           sample_id = 1)
               )
  expect_equal(filter_first_samples(tibble(patient_id = 'a', collection_date = '2022-02-02', sample_id = 1)),
               tibble(patient_id = 'a', collection_date = '2022-02-02', sample_id = 1)
  )
})
