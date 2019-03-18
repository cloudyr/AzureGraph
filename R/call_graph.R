#' Call the Microsoft Graph REST API
#'
#' @param token An Azure OAuth token, of class [AzureToken].
#' @param tenant An Azure Active Directory tenant. Can be a GUID, a domain name, or "myorganization" to use the tenant of the logged-in user.
#' @param operation The operation to perform, which will form part of the URL path.
#' @param options A named list giving the URL query parameters.
#' @param api_version The API version to use, which will form part of the URL sent to the host.
#' @param url A complete URL to send to the host.
#' @param http_verb The HTTP verb as a string, one of `GET`, `PUT`, `POST`, `DELETE`, `HEAD` or `PATCH`.
#' @param http_status_handler How to handle in R the HTTP status code of a response. `"stop"`, `"warn"` or `"message"` will call the appropriate handlers in httr, while `"pass"` ignores the status code.
#' @param auto_refresh Whether to refresh/renew the OAuth token if it is no longer valid.
#' @param ... Other arguments passed to lower-level code, ultimately to the appropriate functions in httr.
#'
#' @details
#' These functions form the low-level interface between R and Microsoft Graph. `call_graph_endpoint` forms a URL from its arguments and passes it to `call_graph_url`.
#'
#' @return
#' If `http_status_handler` is one of `"stop"`, `"warn"` or `"message"`, the status code of the response is checked. If an error is not thrown, the parsed content of the response is returned with the status code attached as the "status" attribute.
#'
#' If `http_status_handler` is `"pass"`, the entire response is returned without modification.
#'
#' @seealso
#' [httr::GET], [httr::PUT], [httr::POST], [httr::DELETE], [httr::stop_for_status], [httr::content]
#' @rdname call_graph
#' @export
call_graph_endpoint <- function(token, tenant="myorganization", operation, ...,
                                options=list(),
                                api_version=getOption("azure_graph_api_version"))
{
    url <- httr::parse_url(token$credentials$resource)
    url$path <- construct_path(api_version, operation)
    url$query <- options

    call_graph_url(token, httr::build_url(url), ...)
}

#' @rdname call_graph
#' @export
call_graph_url <- function(token, url, ...,
                           http_verb=c("GET", "DELETE", "PUT", "POST", "HEAD", "PATCH"),
                           http_status_handler=c("stop", "warn", "message", "pass"),
                           auto_refresh=TRUE)
{
    headers <- process_headers(token, ..., auto_refresh=auto_refresh)

    # do actual API call
    res <- httr::VERB(match.arg(http_verb), url, headers, ...)

    process_response(res, match.arg(http_status_handler))
}


process_headers <- function(token, ..., auto_refresh)
{
    # if token has expired, renew it
    if(auto_refresh && !token$validate())
    {
        message("Access token has expired or is no longer valid; refreshing")
        token$refresh()
    }

    creds <- token$credentials
    host <- httr::parse_url(creds$resource)$host
    headers <- c(Host=host, Authorization=paste(creds$token_type, creds$access_token))

    # default content-type is json, set this if encoding not specified
    dots <- list(...)
    if(is_empty(dots) || !("encode" %in% names(dots)) || dots$encode == "raw")
        headers <- c(headers, `Content-type`="application/json")

    httr::add_headers(.headers=headers)
}


process_response <- function(response, handler)
{
    if(handler != "pass")
    {
        cont <- httr::content(response)
        handler <- get(paste0(handler, "_for_status"), getNamespace("httr"))
        handler(response, paste0("complete operation. Message:\n",
                                 sub("\\.$", "", error_message(cont))))

        if(inherits(cont, "xml_document"))
            cont <- cont #xml2::as_list(cont)  # do we actually get any xml?
        else if(is.null(cont))
            cont <- list()

        attr(cont, "status") <- httr::status_code(response)
        cont
    }
    else response
}


# provide complete error messages from Resource Manager/AMicrosoft Graph/etc
error_message <- function(cont)
{
    # kiboze through possible message locations
    msg <- if(is.character(cont))
        cont
    else if(inherits(cont, "xml_node")) # Graph
        paste(xml2::xml_text(xml2::xml_children(cont)), collapse=": ")
    else if(is.list(cont))
    {
        if(is.character(cont$message))
            cont$message
        else if(is.list(cont$error) && is.character(cont$error$message))
            cont$error$message
        else if(is.list(cont$odata.error)) # Graph OData
            cont$odata.error$message$value
    } 
    else ""

    paste0(strwrap(msg), collapse="\n")
}


# handle different behaviour of file_path on Windows/Linux wrt trailing /
construct_path <- function(...)
{
    sub("/$", "", file.path(..., fsep="/"))
}


# same as AzureRMR::named_list, do not export to avoid conflicts
named_list <- function(lst=NULL, name_fields="name")
{
    if(is_empty(lst))
        return(structure(list(), names=character(0)))

    lst_names <- sapply(name_fields, function(n) sapply(lst, `[[`, n))
    if(length(name_fields) > 1)
    {
        dim(lst_names) <- c(length(lst_names) / length(name_fields), length(name_fields))
        lst_names <- apply(lst_names, 1, function(nn) paste(nn, collapse="/"))
    }
    names(lst) <- lst_names
    dups <- duplicated(tolower(names(lst)))
    if(any(dups))
    {
        duped_names <- names(lst)[dups]
        warning("Some names are duplicated: ", paste(unique(duped_names), collapse=" "), call.=FALSE)
    }
    lst
}


# same as AzureRMR::is_empty, do not export to avoid conflicts
is_empty <- function(x)
{
    length(x) == 0
}
