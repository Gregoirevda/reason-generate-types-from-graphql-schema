open Lwt
open Cohttp
open Cohttp_lwt_unix


let callGraphQLAPI url introspectionQuery =
  Client.post
    ~body: (Cohttp_lwt_body.of_string introspectionQuery)
    ~headers: (Header.of_list [("Content-Type", "application/json")])
     (Uri.of_string url) >>= fun (resp, body) ->
  body |> Cohttp_lwt_body.to_string >|= fun body ->
  body

let getGraphQLSchema url introspectionQuery =
  let body = Lwt_main.run (callGraphQLAPI url introspectionQuery) in
  let json = Yojson.Basic.from_string body in

  (*locally open the JSON manipulation fns*)
  let open Yojson.Basic.Util in
  let graphqlSchema = json |> member "data" in
  graphqlSchema

let () =
  let graphQLSchema = getGraphQLSchema "http://localhost:3010/graphql" GraphQL.introspectionQuery in
  print_endline ("Received body\n")



