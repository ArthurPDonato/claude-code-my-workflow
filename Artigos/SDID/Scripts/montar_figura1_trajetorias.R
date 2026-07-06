library(png)
library(grid)
library(gridExtra)
library(magick)

dir_res <- "C:/Users/TutuSurfer/meu-projeto/Artigos/SDID/Resultados/SDID completo pool completo 6 municipios"

ids   <- c("4306767", "4312609", "4315800", "4321626", "4300851", "4310108")
nomes <- c("Eldorado do Sul", "Muçum†", "Roca Sales", "Travesseiro", "Arambaré", "Igrejinha")

# Carregar, recortar margens brancas e converter para raster
imgs <- lapply(ids, function(id) {
  path <- file.path(dir_res, paste0("municipio_", id, "_completo_trajetorias.png"))
  tmp  <- tempfile(fileext = ".png")
  image_write(image_trim(image_read(path)), tmp)
  rasterGrob(readPNG(tmp), interpolate = TRUE)
})

grobs <- lapply(seq_along(imgs), function(i) {
  arrangeGrob(
    imgs[[i]],
    top     = textGrob(nomes[i], gp = gpar(fontsize = 13, fontface = "bold")),
    padding = unit(0.2, "line")
  )
})

# 3 colunas x 2 linhas — altura ajustada para manter proporção 1.5:1 por painel
# célula: 2500 px largura → 1667 px altura + espaço para título
out_path <- file.path(dir_res, "figura1_trajetorias_todos.png")

png(out_path, width = 7500, height = 3800, res = 300)
grid.arrange(grobs = grobs, ncol = 3, nrow = 2)
dev.off()

cat("Salvo em:", out_path, "\n")
