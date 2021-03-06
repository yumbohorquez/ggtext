#' Richtext labels
#'
#' This geom draws text labels similar to [ggplot2::geom_label()], but formatted
#' using basic markdown/html. Parameter and aesthetic names follow the conventions
#' of [ggplot2::geom_label()], and therefore the appearance of the frame around
#' the label is controlled with `label.colour`, `label.padding`, `label.margin`,
#' `label.size`, `label.r`, even though the same parameters are called `box.colour`,
#' `box.padding`, `box.margin`, `box.size`, and `box.r` in [geom_textbox()]. Most 
#' styling parameters can be used as aesthetics and can be applied separately to
#' each text label drawn. The exception is styling parameters that are specified
#' as grid units (e.g., `label.padding` or `label.r`), which can only be specified
#' for all text labels at once. See examples for details.
#' 
#' @section Aesthetics:
#' 
#' `geom_richtext()` understands the following aesthetics (required 
#' aesthetics are in bold; select aesthetics are annotated):
#' 
#' * **`x`**
#' * **`y`**
#' * **`label`**
#' * `alpha`
#' * `angle`
#' * `colour` Default color of label text and label outline.
#' * `family`
#' * `fontface`
#' * `fill` Default fill color of label background.
#' * `group`
#' * `hjust`
#' * `label.colour` Color of label outline. Overrides `colour`.
#' * `label.size` Width of label outline.
#' * `lineheight`
#' * `size` Default font size of label text.
#' * `text.colour` Color of label text. Overrides `colour`. 
#' * `vjust`
#' 
#' @inheritParams ggplot2::geom_text
#' @inheritParams ggplot2::geom_label
#' @param label.margin Unit vector of length four specifying the margin
#'   outside the text label.
#' @seealso [geom_textbox()], [element_markdown()]
#' @examples
#' library(ggplot2)
#' 
#' df <- data.frame(
#'   label = c(
#'     "Some text **in bold.**",
#'     "Linebreaks<br>Linebreaks<br>Linebreaks",
#'     "*x*<sup>2</sup> + 5*x* + *C*<sub>*i*</sub>",
#'     "Some <span style='color:blue'>blue text **in bold.**</span><br>And *italics text.*<br>
#'       And some <span style='font-size:18pt; color:black'>large</span> text."
#'   ),
#'   x = c(.2, .1, .5, .9),
#'   y = c(.8, .4, .1, .5),
#'   hjust = c(0.5, 0, 0, 1),
#'   vjust = c(0.5, 1, 0, 0.5),
#'   angle = c(0, 0, 45, -45),
#'   color = c("black", "blue", "black", "red"),
#'   fill = c("cornsilk", "white", "lightblue1", "white")
#' )
#' 
#' ggplot(df) +
#'   aes(
#'     x, y, label = label, angle = angle, color = color, fill = fill,
#'     hjust = hjust, vjust = vjust
#'   ) +
#'   geom_richtext() +
#'   geom_point(color = "black", size = 2) +
#'   scale_color_identity() +
#'   scale_fill_identity() +
#'   xlim(0, 1) + ylim(0, 1)
#'   
#' # labels without frame or background are also possible
#' ggplot(df) +
#'   aes(
#'     x, y, label = label, angle = angle, color = color,
#'     hjust = hjust, vjust = vjust
#'   ) +
#'   geom_richtext(
#'     fill = NA, label.color = NA, # remove background and outline
#'     label.padding = grid::unit(rep(0, 4), "pt") # remove padding
#'   ) +
#'   geom_point(color = "black", size = 2) +
#'   scale_color_identity() +
#'   xlim(0, 1) + ylim(0, 1)
#' @export
geom_richtext <- function(mapping = NULL, data = NULL,
                      stat = "identity", position = "identity",
                      ...,
                      nudge_x = 0,
                      nudge_y = 0,
                      label.padding = unit(c(0.25, 0.25, 0.25, 0.25), "lines"),
                      label.margin = unit(c(0, 0, 0, 0), "lines"),
                      label.r = unit(0.15, "lines"),
                      na.rm = FALSE,
                      show.legend = NA,
                      inherit.aes = TRUE)
{
  if (!missing(nudge_x) || !missing(nudge_y)) {
    if (!missing(position)) {
      stop("You must specify either `position` or `nudge_x`/`nudge_y` but not both.", call. = FALSE)
    }

    position <- position_nudge(nudge_x, nudge_y)
  }

  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRichText,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      label.padding = label.padding,
      label.margin = label.margin,
      label.r = label.r,
      na.rm = na.rm,
      ...
    )
  )
}

#' @rdname geom_richtext
#' @format NULL
#' @usage NULL
#' @export
GeomRichText <- ggproto("GeomRichText", Geom,
  required_aes = c("x", "y", "label"),

  default_aes = aes(
    colour = "black", fill = "white", size = 3.88, angle = 0, hjust = 0.5,
    vjust = 0.5, alpha = NA, family = "", fontface = 1, lineheight = 1.2,
    text.colour = NULL, label.colour = NULL, label.size = 0.25
  ),

  draw_panel = function(data, panel_params, coord, 
                        label.padding = unit(c(0.25, 0.25, 0.25, 0.25), "lines"),
                        label.margin = unit(c(0, 0, 0, 0), "lines"),
                        label.r = unit(0.15, "lines"),
                        na.rm = FALSE) {
    data <- coord$transform(data, panel_params)
    if (is.character(data$vjust)) {
      data$vjust <- compute_just(data$vjust, data$y)
    }
    if (is.character(data$hjust)) {
      data$hjust <- compute_just(data$hjust, data$x)
    }

    richtext_grob(
      data$label,
      data$x, data$y, default.units = "native",
      hjust = data$hjust, vjust = data$vjust,
      rot = data$angle,
      padding = label.padding,
      margin = label.margin,
      gp = gpar(
        col = scales::alpha(data$text.colour %||% data$colour, data$alpha),
        fontsize = data$size * .pt,
        fontfamily = data$family,
        fontface = data$fontface,
        lineheight = data$lineheight
      ),
      box_gp = gpar(
        col = scales::alpha(data$label.colour %||% data$colour, data$alpha),
        fill = scales::alpha(data$fill, data$alpha),
        lwd = data$label.size * .pt
      ),
      r = label.r
    )
  },

  draw_key = draw_key_text
)

#' @rdname geom_richtext
#' @format NULL
#' @usage NULL
#' @export
GeomRichtext <- GeomRichText # for automated geom discovery

compute_just <- function(just, x) {
  inward <- just == "inward"
  just[inward] <- c("left", "middle", "right")[just_dir(x[inward])]
  outward <- just == "outward"
  just[outward] <- c("right", "middle", "left")[just_dir(x[outward])]

  unname(c(left = 0, center = 0.5, right = 1,
    bottom = 0, middle = 0.5, top = 1)[just])
}

just_dir <- function(x, tol = 0.001) {
  out <- rep(2L, length(x))
  out[x < 0.5 - tol] <- 1L
  out[x > 0.5 + tol] <- 3L
  out
}
