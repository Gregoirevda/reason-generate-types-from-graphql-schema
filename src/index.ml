open Lwt
open Cohttp
open Cohttp_lwt_unix
open Printf

let graphQLTypesFile = "GraphQLTypes.re"

let callGraphQLAPI url introspectionQuery =
  Client.post
    ~body: (Cohttp_lwt_body.of_string introspectionQuery)
    ~headers: (Header.of_list [("Content-Type", "application/json")])
     (Uri.of_string url) >>= fun (resp, body) ->
  body |> Cohttp_lwt_body.to_string >|= fun body ->
  body

let getGraphQLSchema url introspectionQuery =
  let body = Lwt_main.run (callGraphQLAPI url introspectionQuery) in
  print_endline("Response: " ^ body);
  let json = Yojson.Basic.from_string body in
  (*locally open the JSON manipulation fns*)
  let open Yojson.Basic.Util in
  let graphqlSchema = json |> member "data" in
  graphqlSchema

let getTypesFromGraphQLSchema graphQLSchema =
  let open Yojson.Basic.Util in
  graphQLSchema |> member "__schema" |> member "types" |> to_list

let filterObjectTypes types =
  let open Yojson.Basic.Util in
  List.filter (fun graphQLType -> (graphQLType |> member "kind" |> to_string) = "OBJECT") types

let filterCustomObjectTypes types =
  let open Yojson.Basic.Util in
  List.filter (fun obj ->
      let name = (obj |> member "name" |> to_string) in
      let sub = String.sub name 0 2 in
      sub <> "__"
      ) types

let mapToReasonType types =
  let open Yojson.Basic.Util in
  List.rev_map (fun customObjectType ->
    let name = member "name" customObjectType |> to_string |> String.uncapitalize in
    let jsonFields = member "fields" customObjectType |> to_list in
    let fields = List.map (fun field ->
      let fieldName = member "name" field |> to_string in
      "\t" ^ fieldName ^ ": " ^ (member "type" field |> member "name" |> to_string)
    ) jsonFields in
    let fieldsString = String.concat "\n" fields in
    "type " ^ name ^ " = {\n" ^ fieldsString ^ "\n};\n"
  ) types

let getReasonTypes graphQLSchema =
  (*locally open the JSON manipulation fns*)
  let open Yojson.Basic.Util in
  getTypesFromGraphQLSchema graphQLSchema |> filterObjectTypes |> filterCustomObjectTypes |> mapToReasonType

let writeReasonTypesToFile reasonTypes =
  let oc = open_out graphQLTypesFile in
    fprintf oc "%s\n" (String.concat "\n" reasonTypes);
    close_out oc;
    print_endline ("Received body\n")

let () =
  let graphQLSchema = getGraphQLSchema "http://localhost:3010/graphql" GraphQL.introspectionQuery in
  let reasonTypes = getReasonTypes graphQLSchema in
  writeReasonTypesToFile reasonTypes;





