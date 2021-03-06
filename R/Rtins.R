#' @useDynLib Rtins, .registration=TRUE
#' @importFrom Rcpp evalCpp
NULL


#' Sniff a PCAP file
#' 
#' @param iface network interface to sniff.
#' @param filter BPF filter to apply for reading the capture.
#' @param num number of packets to collect
#' @param layers number of layers to decode.
#' 
#' @examples
#' ## Not run:
#' interface<-'eth0'
#' pcap <- sniff_pcap(interface)
#' head(pcap)
#' summary(pcap)
#' head(sniff_pcap(interface, filter = "udp and dst port 53", num = 20))
#' 
#' ## End(Not run)
#' @export
sniff_pcap <- function(iface, filter, num,layers=3) {
  require(data.table)
  stopifnot(layers > 0)
  if (missing(filter)) filter <- ""
  if (missing(num)) num <- 10
  df <- as.data.table(sniff_pcap_(iface, filter, num, layers))
  class(df) <- c("pcap", class(df))
  attr(df, "iface") <- iface
  attr(df, "filter") <- filter
  attr(df, "layers") <- layers
  df
}
#' Read a PCAP file
#' 
#' @param fname path to the capture file.
#' @param filter BPF filter to apply for reading the capture.
#' @param layers number of layers to decode.
#' 
#' @examples
#' ## Not run:
#' fname <- system.file("pcaps/http.cap", package="Rtins")
#' pcap <- read_pcap(fname)
#' head(pcap)
#' summary(pcap)
#' ## End(Not run)
#' @export
read_pcap <- function(fname, filter, layers=3) {
  require(data.table)
  fname <- path.expand(fname)
  stopifnot(file.exists(fname))
  stopifnot(layers > 0)
  if (missing(filter)) filter <- ""
  df <- as.data.table(read_pcap_(fname, filter, layers))
  class(df) <- c("pcap", class(df))
  attr(df, "fname") <- fname
  attr(df, "filter") <- filter
  attr(df, "layers") <- layers
  df
}

#' @export
summary.pcap <- function(object, ...) {
  ts_first <- object$tv_sec[[1]] + object$tv_usec[[1]]*1e-6
  ts_last <- object$tv_sec[[nrow(object)]] + object$tv_usec[[nrow(object)]]*1e-6
  ts_span <- ts_last - ts_first
  cat("File info\n",
      "  Capture file   : ", attr(object, "iface"), "\n",
      "  Filter applied : ", attr(object, "filter"), "\n",
      "  Layers decoded : ", attr(object, "layers"), "\n",
      "  Length (bytes) : ", file.size(attr(object, "iface")), "\n\n",
      "Time info\n",
      "  First packet   : ", format(as.POSIXct(ts_first, origin="1970-01-01 00:00:00", tz="UTC")), "\n",
      "  Last packet    : ", format(as.POSIXct(ts_last, origin="1970-01-01 00:00:00", tz="UTC")), "\n\n",
      "Statistics\n",
      "  Packets        : ", nrow(object), "\n",
      "  Time span (s)  : ", ts_span, "\n",
      "  Average pps    : ", nrow(object) / ts_span, "\n",
      "  Average Mbps   : ", sum(object$layer_1_size) * 8 / ts_span / 1e6,
      sep="")
}
