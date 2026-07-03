-module('Rata.bridge').
-export([request/1]).

request(Spec) ->
    try
        case ensure_apps() of
            ok -> do_request(Spec);
            {error, AppReason} -> {error, backend_error(format_reason(AppReason))}
        end
    catch
        Class:Reason:Stack ->
            {error,
                backend_error(
                    iolist_to_binary(
                        io_lib:format(
                            "~p:~p ~p",
                            [Class, Reason, Stack]
                        )
                    )
                )}
    end.

ensure_apps() ->
    case ensure_app(inets) of
        ok -> ensure_app(ssl);
        Error -> Error
    end.

ensure_app(App) ->
    case application:ensure_all_started(App) of
        {ok, _Started} -> ok;
        {error, Reason} -> {error, {App, Reason}}
    end.

do_request({'rata_fetch_FetchSpec', Method0, Url0, Headers0, Body0, Timeout0, Redirects0}) ->
    Method = method_atom(Method0),
    Url = binary_to_list(Url0),
    case validate_url(Url0) of
        ok ->
            Headers = headers_to_httpc(Headers0),
            Body = body_to_binary(Body0),
            Request = request_tuple(Url, Headers, Body),
            HttpOptions = http_options(Url0, Timeout0, Redirects0),
            Options = [{body_format, binary}],
            case httpc:request(Method, Request, HttpOptions, Options) of
                {ok, {{_Version, Status, Reason}, ResponseHeaders, ResponseBody}} ->
                    {ok,
                        {'rata_fetch_Response', Status, to_binary(Reason),
                            headers_from_httpc(ResponseHeaders), to_binary(ResponseBody)}};
                {ok, {Status, ResponseHeaders, ResponseBody}} when is_integer(Status) ->
                    {ok,
                        {'rata_fetch_Response', Status, <<>>, headers_from_httpc(ResponseHeaders),
                            to_binary(ResponseBody)}};
                {error, Reason} ->
                    {error, map_error(Reason)};
                Other ->
                    {error, backend_error(format_reason(Other))}
            end;
        {unsupported, Reason} ->
            {error, {'rata_fetch_Unsupported', Reason}};
        {error, Reason} ->
            {error, {'rata_fetch_InvalidUrl', Reason}}
    end;
do_request(Other) ->
    {error, backend_error(iolist_to_binary(io_lib:format("bad fetch spec: ~p", [Other])))}.

validate_url(Url) ->
    case uri_string:parse(Url) of
        #{scheme := <<"http">>, host := _Host} ->
            ok;
        #{scheme := <<"https">>, host := _Host} ->
            ok;
        #{scheme := Scheme} when is_binary(Scheme) ->
            {unsupported, <<"unsupported URL scheme: ", Scheme/binary>>};
        _ ->
            {error, <<"expected absolute http or https URL">>}
    end.

method_atom({'rata_fetch_GET'}) -> get;
method_atom({'rata_fetch_POST'}) -> post;
method_atom({'rata_fetch_PUT'}) -> put;
method_atom({'rata_fetch_PATCH'}) -> patch;
method_atom({'rata_fetch_DELETE'}) -> delete;
method_atom({'rata_fetch_HEAD'}) -> head;
method_atom({'rata_fetch_OPTIONS'}) -> options.

headers_to_httpc(Headers) ->
    [
        {binary_to_list(Name), binary_to_list(Value)}
     || {'rata_fetch_Header', Name, Value} <- Headers
    ].

headers_from_httpc(Headers) ->
    [
        {'rata_fetch_Header', to_binary(Name), to_binary(Value)}
     || {Name, Value} <- Headers
    ].

body_to_binary({'rata_fetch_Empty'}) -> none;
body_to_binary({'rata_fetch_Bytes', Body}) -> Body;
body_to_binary({'rata_fetch_Text', Body}) -> Body.

request_tuple(Url, Headers, none) ->
    {Url, Headers};
request_tuple(Url, Headers, Body) ->
    {ContentType, HeadersWithoutContentType} = take_content_type(Headers),
    {Url, HeadersWithoutContentType, ContentType, Body}.

take_content_type(Headers) ->
    take_content_type(Headers, []).

take_content_type([], Acc) ->
    {"application/octet-stream", lists:reverse(Acc)};
take_content_type([{Name, Value} | Rest], Acc) ->
    case string:casefold(Name) of
        "content-type" -> {Value, lists:reverse(Acc) ++ Rest};
        _ -> take_content_type(Rest, [{Name, Value} | Acc])
    end.

http_options(Url, Timeout0, Redirects0) ->
    tls_options(Url) ++ maybe_timeout(Timeout0) ++ maybe_redirects(Redirects0).

tls_options(Url) ->
    case uri_string:parse(Url) of
        #{scheme := <<"https">>} -> [{ssl, httpc:ssl_verify_host_options(true)}];
        _ -> []
    end.

maybe_timeout({'just', Timeout}) when is_integer(Timeout), Timeout >= 0 ->
    [{timeout, Timeout}];
maybe_timeout(_) ->
    [].

maybe_redirects({'just', Follow}) when is_boolean(Follow) ->
    [{autoredirect, Follow}];
maybe_redirects(_) ->
    [].

map_error(timeout) -> {'rata_fetch_Timeout'};
map_error({timeout, _}) -> {'rata_fetch_Timeout'};
map_error(nxdomain) -> {'rata_fetch_DnsError', <<"nxdomain">>};
map_error(econnrefused) -> {'rata_fetch_ConnectionError', <<"econnrefused">>};
map_error(econnreset) -> {'rata_fetch_ConnectionError', <<"econnreset">>};
map_error(closed) -> {'rata_fetch_ConnectionError', <<"closed">>};
map_error(max_redirect) -> {'rata_fetch_TooManyRedirects'};
map_error({failed_connect, Details}) -> map_failed_connect(Details);
map_error({tls_alert, Alert}) -> {'rata_fetch_TlsError', format_reason(Alert)};
map_error({failed_connect, _, Details}) -> map_failed_connect(Details);
map_error(Reason) -> backend_error(format_reason(Reason)).

map_failed_connect(Details) ->
    Text = format_reason(Details),
    case contains_any(Text, [<<"nxdomain">>, <<"not_found">>]) of
        true ->
            {'rata_fetch_DnsError', Text};
        false ->
            case contains_any(Text, [<<"tls">>, <<"ssl">>, <<"certificate">>]) of
                true -> {'rata_fetch_TlsError', Text};
                false -> {'rata_fetch_ConnectionError', Text}
            end
    end.

contains_any(_Text, []) ->
    false;
contains_any(Text, [Needle | Rest]) ->
    case binary:match(Text, Needle) of
        nomatch -> contains_any(Text, Rest);
        _ -> true
    end.

backend_error(Reason) ->
    {'rata_fetch_BackendError', Reason}.

format_reason(Reason) when is_binary(Reason) -> Reason;
format_reason(Reason) when is_atom(Reason) -> atom_to_binary(Reason);
format_reason(Reason) -> iolist_to_binary(io_lib:format("~p", [Reason])).

to_binary(Value) when is_binary(Value) -> Value;
to_binary(Value) when is_list(Value) -> unicode:characters_to_binary(Value);
to_binary(Value) when is_atom(Value) -> atom_to_binary(Value);
to_binary(Value) when is_integer(Value) -> integer_to_binary(Value);
to_binary(Value) -> format_reason(Value).
