% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/az_user.R
\docType{class}
\name{az_user}
\alias{az_user}
\title{User in Azure Active Directory}
\format{
An R6 object of class \code{az_user}, inheriting from \code{az_object}.
}
\description{
Class representing an AAD user account.
}
\section{Fields}{

\itemize{
\item \code{token}: The token used to authenticate with the Graph host.
\item \code{tenant}: The Azure Active Directory tenant for this user.
\item \code{type}: always "user" for a user object.
\item \code{properties}: The user properties.
}
}

\section{Methods}{

\itemize{
\item \code{new(...)}: Initialize a new user object. Do not call this directly; see 'Initialization' below.
\item \code{delete(confirm=TRUE)}: Delete a user account. By default, ask for confirmation first.
\item \code{update(...)}: Update the user information in Azure Active Directory.
\item \code{do_operation(...)}: Carry out an arbitrary operation on the user account.
\item \code{sync_fields()}: Synchronise the R object with the app data in Azure Active Directory.
\item \code{list_group_memberships()}: Return the IDs of all groups this user is a member of.
\item \code{list_object_memberships()}: Return the IDs of all groups, administrative units and directory roles this user is a member of.
\item \code{list_direct_memberships(id_only=TRUE)}: List the groups and directory roles this user is a direct member of. Set \code{id_only=TRUE} to return only a vector of IDs (the default), or \code{id_only=FALSE} to return a list of group objects.
\item \code{list_owned_objects(type=c("user", "group", "application", "servicePrincipal"))}: List directory objects (groups/apps/service principals) owned by this user. Specify the \code{type} argument to filter the result for specific object type(s).
\item \code{list_created_objects(type=c("user", "group", "application", "servicePrincipal"))}: List directory objects (groups/apps/service principals) created by this user. Specify the \code{type} argument to filter the result for specific object type(s).
\item \code{list_owned_devices()}: List the devices owned by this user.
\item \code{list_registered_devices()}: List the devices registered by this user.
\item \code{reset_password(password=NULL, force_password_change=TRUE)}: Resets a user password. By default the new password will be randomly generated, and must be changed at next login.
}
}

\section{Initialization}{

Creating new objects of this class should be done via the \code{create_user} and \code{get_user} methods of the \link{ms_graph} and \link{az_app} classes. Calling the \code{new()} method for this class only constructs the R object; it does not call the Microsoft Graph API to create the actual user account.
}

\examples{
\dontrun{

gr <- get_graph_login()

# my user account
gr$get_user()

# another user account
usr <- gr$get_user("myname@aadtenant.com")

grps <- usr$list_direct_memberships()
head(grps)

# owned objects
usr$list_owned_objects()

# owned apps and service principals
usr$list_owned_objects(type=c("application", "servicePrincipal"))

}
}
\seealso{
\link{ms_graph}, \link{az_app}, \link{az_group}, \link{az_device}, \link{az_object}

\href{https://docs.microsoft.com/en-us/graph/overview}{Microsoft Graph overview},
\href{https://docs.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0}{REST API reference}
}
