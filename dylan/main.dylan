module: wiki-internal


define function sort-table
    (the-table :: <table>, key :: <function>,
     #key test :: <function> = \>)
 => (entries :: <sequence>)
  sort(map-as(<vector>, identity, the-table),
       test: method (first, second)
               test(key(first), key(second))
             end);
end function sort-table;

// It's unintuitive for the user to have to set a content directory for
// "web-framework" instead of "wiki".
//
define sideways method process-config-element
    (server :: <http-server>, node :: xml/<element>, name == #"wiki")
  process-config-element(server, node, #"web-framework")
end method process-config-element;

define constant $wiki-http-server = make(<http-server>);

define url-map on $wiki-http-server
  url wiki-url("/recent-changes")
    action get () => *recent-changes-page*,
    action get ("^feed/?$") => do-feed;

  url wiki-url("/users")
    action get () =>
      *list-users-page*,
    action post () =>
      method ()
        redirect-to(user-permanent-link(get-query-value("query")))
      end,
    action get ("^(?P<username>[^/]+)/?$") =>
      show-user,
    action get ("^(?P<username>[^/]+)/edit$") =>
      show-edit-user,
    action (post, put) ("^(?P<username>[^/]+)$") =>
      do-save-user,
    action get ("^(?P<username>[^/]+)/remove$") =>
      (bind-user, show-remove-user),
    action (delete, post) ("^(?P<username>[^/]+)/remove$") =>
      do-remove-user;

  url wiki-url("/register")
    // For now the users page gives a way to create an account.
    // Eventually the registration page should be more specialized.
    action get () => *list-users-page*;

  url wiki-url("/pages")
    action get () => do-pages,
    action get ("^(?P<title>[^/]+)/?$") =>
      (bind-page, show-page),
    action get ("^(?P<title>[^/]+)/edit$") =>
      (bind-page, show-edit-page),
    action (post, put) ("^(?P<title>[^/]+)(/(edit)?)?$") =>
      do-save-page,
    action get ("^(?P<title>[^/]+)/remove$") =>
      (bind-page, show-remove-page),
    action (delete, post) ("^(?P<title>[^/]+)/remove$") =>
      do-remove-page,
   // versions
    action get ("^(?P<title>[^/]+)/versions$") => 
      (bind-page, show-page-versions),
    action get ("^(?P<title>[^/]+)/versions/(?P<version>\\d+)$") =>
      (bind-page, show-page),
    action get ("^(?P<title>[^/]+)/versions/(?P<a>\\d+)/diff(/(?P<b>\\d+))?$") => 
      (bind-page, show-page-versions-differences),
    // connections
    action get ("^(?P<title>[^/]+)/connections$") => 
      (bind-page, show-page-connections),
    // authors
    action get ("^(?P<title>[^/]+)/authors$") =>
      (bind-page, show-page-authors),
    // access
    action get ("^(?P<title>[^/]+)/access") =>
      (bind-page, show-page-access);

  url wiki-url("/groups")
    action get () => do-groups,
    action get ("^(?P<name>[^/]+)/?$") =>
      (bind-group, show-group),
    action get ("^(?P<name>[^/]+)/edit$") =>
      (bind-group, show-edit-group),
    action (post, put) ("^(?P<name>[^/]+)(/(edit)?)?$") =>
      do-save-group,
    action get ("^(?P<name>[^/]+)/remove$") =>
      (bind-group, show-remove-group),
    action (delete, post) ("^(?P<name>[^/]+)/remove$") =>
      do-remove-group,
    // members
    action get ("^(?P<name>[^/]+)/members$") =>
      (bind-group, edit-group-members),
    action (post, put) ("^(?P<name>[^/]+)/members$") =>
      do-save-group-members,
    // authorization
    action get ("^(?P<name>[^/]+)/authorization$") =>
      (bind-group, edit-group-authorization),
    action (post, put) ("^(?P<name>[^/]+)/authorization$") =>
      do-save-group-authorization;

/***** We'll use Google or Yahoo custom search, at least for a while
  url wiki-url("/search")
    action (get, post) () => $search-page;
*/

  url wiki-url("/login")
    action (get, post) () => curry(login, realm: "dylan-wiki");

  url wiki-url("/logout")
    action (get, post) () => logout;

  url wiki-url("/")
    action get () => *main-page*;
end url-map;

define function main
    ()
  let filename = locator-name(as(<file-locator>, application-name()));
  if (split(filename, ".")[0] = "wiki")
    koala-main(server: $wiki-http-server,
               description: "Dylan wiki")
  end;
end;

begin
  main();
end;
