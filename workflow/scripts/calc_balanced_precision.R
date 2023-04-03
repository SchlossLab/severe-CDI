
#' Calculate the fraction of positives, i.e. baseline precision for a PRC curve
#'
#' @inheritParams get_outcome_type
#' @inheritParams run_ml
#' @inheritParams calc_model_sensspec
#' @param pos_outcome the positive outcome from `outcome_colname`,
#'   e.g. "cancer" for the `otu_mini_bin` dataset.
#'
#' @return the baseline precision based on the fraction of positives
#' @export
#' @author Kelly Sovacool, \email{sovacool@@umich.edu}
#'
#' @examples
#' # calculate the baseline precision
#' data.frame(y = c("a", "b", "a", "b")) %>%
#'   calc_baseline_precision("y", "a")
#'
#'
#' calc_baseline_precision(otu_mini_bin,
#'   outcome_colname = "dx",
#'   pos_outcome = "cancer"
#' )
#'
#'
#' # if you're not sure which outcome was used as the 'positive' outcome during
#' # model training, you can access it from the trained model and pass it along:
#' calc_baseline_precision(otu_mini_bin,
#'   outcome_colname = "dx",
#'   pos_outcome = otu_mini_bin_results_glmnet$trained_model$levels[1]
#' )
#'
calc_baseline_precision <- function(dataset,
                                    outcome_colname = NULL,
                                    pos_outcome = NULL) {
  npos <- dataset %>%
    dplyr::filter(!!rlang::sym(outcome_colname) == pos_outcome) %>%
    nrow()
  ntot <- dataset %>% nrow()
  baseline_prec <- npos / ntot
  return(baseline_prec)
}

#' Calculate balanced precision given actual and baseline precision
#'
#' Implements Equation 1 from Wu _et al._ 2021 \doi{10.1016/j.ajhg.2021.08.012}.
#' It is the same as Equation 7 if `AUPRC` (aka `prAUC`) is used in place of `precision`.
#'
#' @param precision actual precision of the model.
#' @param prior baseline precision, aka frequency of positives.
#'   Can be calculated with [calc_baseline_precision]
#'
#' @return the expected precision if the data were balanced
#' @export
#' @author Kelly Sovacool \email{sovacool@@umich.edu}
#'
#' @examples
#' prior <- calc_baseline_precision(otu_mini_bin,
#'   outcome_colname = "dx",
#'   pos_outcome = "cancer"
#' )
#' calc_balanced_precision(otu_mini_bin_results_rf$performance$Precision, prior)
#'
#' otu_mini_bin_results_rf$performance %>%
#'   dplyr::mutate(
#'     balanced_precision = calc_balanced_precision(Precision, prior),
#'     aubprc = calc_balanced_precision(prAUC, prior)
#'   ) %>%
#'   dplyr::select(AUC, Precision, balanced_precision, aubprc)
#'
#' # cumulative performance for a single model
#' sensspec_1 <- calc_model_sensspec(
#'   otu_mini_bin_results_glmnet$trained_model,
#'   otu_mini_bin_results_glmnet$test_data,
#'   "dx"
#' )
#' head(sensspec_1)
#' prior <- calc_baseline_precision(otu_mini_bin,
#'   outcome_colname = "dx",
#'   pos_outcome = "cancer"
#' )
#' sensspec_1 %>%
#'   dplyr::mutate(balanced_precision = calc_balanced_precision(precision, prior)) %>%
#'   dplyr::rename(recall = sensitivity) %>%
#'   calc_mean_perf(group_var = recall, sum_var = balanced_precision) %>%
#'   plot_mean_prc(ycol = mean_balanced_precision)
calc_balanced_precision <-
  function(precision, prior) {
    if (is.na(precision) | is.na(prior)) {
            bprec <- NA
    } else {
      bprec <- precision * (1 - prior) / (
        precision * (1 - prior) + (1 - precision) * prior
      )
    }
    return(bprec)
  }
