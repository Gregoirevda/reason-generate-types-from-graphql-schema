open Ocamlbuild_plugin
open Command

let () =
  dispatch begin function
  | After_rules ->
     ocaml_lib ~extern:true ~dir:"+lablGL" "lablgl";
     ocaml_lib ~extern:true ~dir:"+lablGL" "lablglut";
  | _ -> ()
  end