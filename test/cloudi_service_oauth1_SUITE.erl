%-*-Mode:erlang;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
% ex: set ft=erlang fenc=utf-8 sts=4 ts=4 sw=4 et:
-module(cloudi_service_oauth1_SUITE).
-behaviour(cloudi_service).

%% cloudi_service callbacks
-export([cloudi_service_init/3,
         cloudi_service_handle_request/11,
         cloudi_service_handle_info/3,
         cloudi_service_terminate/2]).

%% CT callbacks
-export([all/0,
         groups/0,
         suite/0,
         init_per_suite/1,
         end_per_suite/1,
         group/1,
         init_per_group/2,
         end_per_group/2,
         init_per_testcase/2,
         end_per_testcase/2]).

%% test callbacks
-export([t_debug_without_db_1/1,
         t_debug_without_db_2/1]).

-include_lib("common_test/include/ct.hrl").
-include_lib("cloudi_core/include/cloudi_logger.hrl").

%%%------------------------------------------------------------------------
%%% Callback functions from cloudi_service
%%%------------------------------------------------------------------------

cloudi_service_init(Args, _Prefix, Dispatcher) ->
    Defaults = [
        {mode,                             undefined}],
    [Mode] = cloudi_proplists:take_values(Defaults, Args),
    if
        Mode =:= example ->
            cloudi_service:subscribe(Dispatcher, "photos/get")
    end,
    {ok, Mode}.

cloudi_service_handle_request(_Type, _Name, _Pattern, _RequestInfo, _Request,
                              _Timeout, _Priority, _TransId, _Pid,
                              example = State, _Dispatcher) ->
    ResponseInfo = [
        {<<"content-type">>, <<"image/jpeg">>},
        {<<"content-disposition">>,
         <<"attachment; filename=\"vacation.jpg\"">>}],
    Response = <<"PHOTO_DATA">>,
    {reply, ResponseInfo, Response, State}.

cloudi_service_handle_info(Request, State, _) ->
    ?LOG_WARN("Unknown info \"~p\"", [Request]),
    {noreply, State}.

cloudi_service_terminate(_, _) ->
    ok.

%%%------------------------------------------------------------------------
%%% Callback functions from CT
%%%------------------------------------------------------------------------

all() ->
    [{group, debug_with_no_db}].

groups() ->
    [{debug_with_no_db, [],
      [t_debug_without_db_1,
       t_debug_without_db_2]}].

suite() ->
    [{ct_hooks, [cth_surefire]},
     {timetrap, 5100}].

init_per_suite(Config) ->
    ok = reltool_util:application_start(cloudi_core, [], infinity),
    Config.

end_per_suite(_Config) ->
    ok = reltool_util:application_stop(cloudi_core),
    ok.

group(_GroupName) ->
    [].

init_per_group(_GroupName, Config) ->
    Config.

end_per_group(_GroupName, Config) ->
    Config.

init_per_testcase(t_debug_without_db_1, Config) ->
    {ok, ServiceIds} = cloudi_service_api:services_add([
        {internal,
            "/oauth_db/",
            cloudi_service_db_pgsql,
            [{driver, semiocast}, % semiocast | wg
             {output, internal},
             {internal_interface, common},
             {hostname, "127.0.0.1"},
             {port, 5432},
             {username, "cloudi_tests"},
             {password, "cloudi_tests"},
             {database, "cloudi_tests"},
             {timeout, 30000}, % milliseconds
             {debug, true}],
            none,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
        {internal,
            "/",
            ?MODULE,
            [{mode, example}],
            immediate_closest,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
        {internal,
            "/",
            cloudi_service_oauth1,
            [{database_type, pgsql},
             {database, "/oauth_db/cloudi_tests"},
             {url_host, "https://photos.example.net"},
             {debug, true}],
            immediate_closest,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []}
        ], infinity),
    [{service_ids, ServiceIds} | Config];
init_per_testcase(t_debug_without_db_2, Config) ->
    {ok, ServiceIds} = cloudi_service_api:services_add([
        {internal,
            "/oauth_db/",
            cloudi_service_db_pgsql,
            [{driver, semiocast}, % semiocast | wg
             {output, internal},
             {internal_interface, common},
             {hostname, "127.0.0.1"},
             {port, 5432},
             {username, "cloudi_tests"},
             {password, "cloudi_tests"},
             {database, "cloudi_tests"},
             {timeout, 30000}, % milliseconds
             {debug, true}],
            none,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
        {internal,
            "/",
            ?MODULE,
            [{mode, example}],
            immediate_closest,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []},
        {internal,
            "/",
            cloudi_service_oauth1,
            [{database_type, pgsql},
             {database, "/oauth_db/cloudi_tests"},
             {url_host, "http://photos.example.net"},
             {debug, true}],
            immediate_closest,
            5000, 5000, 5000, undefined, undefined, 1, 5, 300, []}
        ], infinity),
    [{service_ids, ServiceIds} | Config].

end_per_testcase(_TestCase, Config) ->
    {value, {_, ServiceIds}, NewConfig} = lists:keytake(service_ids, 1, Config),
    ok = cloudi_service_api:services_remove(ServiceIds, infinity),
    NewConfig.

%%%------------------------------------------------------------------------
%%% test cases
%%%------------------------------------------------------------------------

t_debug_without_db_1(_Config) ->
    % OAuth requests based on http://tools.ietf.org/html/rfc5849#section-1.2
    Context = cloudi:new(),

    % (HTTPS from http://tools.ietf.org/html/rfc5849#section-1.2 #1)
    % POST /initiate HTTP/1.1
    % Host: photos.example.net
    % Authorization: OAuth realm="Photos",
    %    oauth_consumer_key="dpf43f3p2l4k3l03",
    %    oauth_signature_method="HMAC-SHA1",
    %    oauth_timestamp="137131200",
    %    oauth_nonce="wIjqoS",
    %    oauth_callback="http%3A%2F%2Fprinter.example.com%2Fready",
    %    oauth_signature="74KNZJeDHnMBp0EMJ9ZHt%2FXKycU%3D"
    Name1 = "/initiate/post",
    RequestInfo1 = [
        {<<"url-path">>, <<"/initiate">>}, % <- from cloudi_service_http_cowboy
        {<<"host">>, <<"photos.example.net">>},
        {<<"authorization">>,
         <<"OAuth realm=\"Photos\","
               "oauth_consumer_key=\"dpf43f3p2l4k3l03\","
               "oauth_signature_method=\"HMAC-SHA1\","
               "oauth_timestamp=\"137131200\","
               "oauth_nonce=\"wIjqoS\","
               "oauth_callback=\"http%3A%2F%2Fprinter.example.com%2Fready\","
               "oauth_signature=\"74KNZJeDHnMBp0EMJ9ZHt%2FXKycU%3D\"">>}],
    Request1 = <<>>,

    % HTTP/1.1 200 OK
    % Content-Type: application/x-www-form-urlencoded
    %
    % oauth_token=hh5s93j4hdidpola&oauth_token_secret=hdhd0244k9j7ao03&
    % oauth_callback_confirmed=true
    ResponseInfo1 = [
        {<<"content-type">>, <<"application/x-www-form-urlencoded">>}],
    Response1 = <<"oauth_token=hh5s93j4hdidpola&"
                  "oauth_token_secret=hdhd0244k9j7ao03&"
                  "oauth_callback_confirmed=true">>,
    {ok, ResponseInfo1, Response1} = cloudi:send_sync(Context, Name1,
                                                      RequestInfo1, Request1,
                                                      undefined, undefined),

    % (HTTPS from http://tools.ietf.org/html/rfc5849#section-1.2 #2)
    % https://photos.example.net/authorize?oauth_token=hh5s93j4hdidpola
    Name2 = "/authorize/get",
    RequestInfo2 = [
        {<<"url-path">>, <<"/authorize">>}, % <- from cloudi_service_http_cowboy
        {<<"host">>, <<"photos.example.net">>}],
    Request2 = <<"oauth_token=hh5s93j4hdidpola">>,

    % http://printer.example.com/ready?
    % oauth_token=hh5s93j4hdidpola&oauth_verifier=hfdp7dh39dks9884
    ResponseInfo2 = [
        {<<"status">>, <<"302">>},
        {<<"location">>,
         <<"http://printer.example.com/ready?"
           "oauth_token=hh5s93j4hdidpola&oauth_verifier=hfdp7dh39dks9884">>}],
    Response2 = <<>>,
    {ok, ResponseInfo2, Response2} = cloudi:send_sync(Context, Name2,
                                                      RequestInfo2, Request2,
                                                      undefined, undefined),

    % (HTTPS from http://tools.ietf.org/html/rfc5849#section-1.2 #3)
    % POST /token HTTP/1.1
    % Host: photos.example.net
    % Authorization: OAuth realm="Photos",
    %    oauth_consumer_key="dpf43f3p2l4k3l03",
    %    oauth_token="hh5s93j4hdidpola",
    %    oauth_signature_method="HMAC-SHA1",
    %    oauth_timestamp="137131201",
    %    oauth_nonce="walatlh",
    %    oauth_verifier="hfdp7dh39dks9884",
    %    oauth_signature="gKgrFCywp7rO0OXSjdot%2FIHF7IU%3D"
    Name3 = "/token/post",
    RequestInfo3 = [
        {<<"url-path">>, <<"/token">>}, % <- from cloudi_service_http_cowboy
        {<<"host">>, <<"photos.example.net">>},
        {<<"authorization">>,
         <<"OAuth realm=\"Photos\","
               "oauth_consumer_key=\"dpf43f3p2l4k3l03\","
               "oauth_token=\"hh5s93j4hdidpola\","
               "oauth_signature_method=\"HMAC-SHA1\","
               "oauth_timestamp=\"137131201\","
               "oauth_nonce=\"walatlh\","
               "oauth_verifier=\"hfdp7dh39dks9884\","
               "oauth_signature=\"gKgrFCywp7rO0OXSjdot%2FIHF7IU%3D\"">>}],
    Request3 = <<>>,

    % HTTP/1.1 200 OK
    % Content-Type: application/x-www-form-urlencoded
    %
    % oauth_token=nnch734d00sl2jdk&oauth_token_secret=pfkkdhi9sl3r4s00
    ResponseInfo3 = [
        {<<"content-type">>, <<"application/x-www-form-urlencoded">>}],
    Response3 = <<"oauth_token=nnch734d00sl2jdk&"
                  "oauth_token_secret=pfkkdhi9sl3r4s00">>,
    {ok, ResponseInfo3, Response3} = cloudi:send_sync(Context, Name3,
                                                      RequestInfo3, Request3,
                                                      undefined, undefined),
    ok.

t_debug_without_db_2(_Config) ->
    % OAuth requests based on http://tools.ietf.org/html/rfc5849#section-1.2
    Context = cloudi:new(),

    % (HTTP from http://tools.ietf.org/html/rfc5849#section-1.2 #4)
    % GET /photos?file=vacation.jpg&size=original HTTP/1.1
    % Host: photos.example.net
    % Authorization: OAuth realm="Photos",
    %    oauth_consumer_key="dpf43f3p2l4k3l03",
    %    oauth_token="nnch734d00sl2jdk",
    %    oauth_signature_method="HMAC-SHA1",
    %    oauth_timestamp="137131202",
    %    oauth_nonce="chapoH",
    %    oauth_signature="MdpQcU8iPSUjWoN%2FUDMsK2sui9I%3D"
    Name4 = "/verify/photos/get",
    RequestInfo4 = [
        {<<"url-path">>, <<"/photos">>}, % <- matches example URL and signature
        {<<"host">>, <<"photos.example.net">>},
        {<<"authorization">>,
         <<"OAuth realm=\"Photos\","
               "oauth_consumer_key=\"dpf43f3p2l4k3l03\","
               "oauth_token=\"nnch734d00sl2jdk\","
               "oauth_signature_method=\"HMAC-SHA1\","
               "oauth_timestamp=\"137131202\","
               "oauth_nonce=\"chapoH\","
               "oauth_signature=\"MdpQcU8iPSUjWoN%2FUDMsK2sui9I%3D\"">>}],
    Request4 = <<"file=vacation.jpg&size=original">>,
    ResponseInfo4 = [
        {<<"content-type">>, <<"image/jpeg">>},
        {<<"content-disposition">>,
         <<"attachment; filename=\"vacation.jpg\"">>}],
    Response4 = <<"PHOTO_DATA">>,
    {ok, ResponseInfo4, Response4} = cloudi:send_sync(Context, Name4,
                                                      RequestInfo4, Request4,
                                                      undefined, undefined),
    ok.

%%%------------------------------------------------------------------------
%%% Private functions
%%%------------------------------------------------------------------------

