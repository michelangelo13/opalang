(*
    Copyright © 2011 MLstate

    This file is part of Opa.

    Opa is free software: you can redistribute it and/or modify it under the
    terms of the GNU Affero General Public License, version 3, as published by
    the Free Software Foundation.

    Opa is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
    more details.

    You should have received a copy of the GNU Affero General Public License
    along with Opa. If not, see <http://www.gnu.org/licenses/>.
*)
(** Accept:

    Module for handling HTTP request Accept* header values.

    Method:
    1) We provide a regexp for splitting the first value,
       eg. '/' for Accept: text/html, '-' for Accept-Language: en-GB.
    2) We call the parser routine to break up the input string (make)
       into a (currently abstract) internal type.
    3) Various routines are provided to handle the "q" values, either
       by ranking them according to decreasing "q" and accessing them
       sequentially (q_rank, q_nth) or by providing a list of values
       (generated by make_el) and calling q_preferred to return the
       preferred value.
    4) Routines are provided to extract the values from request headers
       and to replace existing values in request headers with new ones.
    5) Currently, the values are managed as string lists, so for example,
       "text/html;level=1;q=0.5" is handled as (["text";"html"],[["level";"1"]],Some 0.5).
       Remember you can convert back and forward with make_el and string_of_el.

*)
open HttpServerTypes

(** Concrete type of elements in the list of values.
    Does for the internal representation and for user-generated values.
    For example:
      "text/html;level=1;q=0.5"
    is represented as:
      (["text"; "html"], [["level"; "1"]], Some 0.5)
    The quality value is ignored in user-generated instances of this type.
*)
type el = string list * string list list * float option

(** Abstract type for parsed headers.
    Stores enough information to be able to reconstruct the
    original string from internal information, including the comment.
*)
type t (*= string option * char option * el list*)

(** Some precompiled regexp values for use with the input parser.
    regexp3 constructs a fresh regexp from a given character.
    regexp2sl is a precompiled regexp for '/' (ie. Accept: headers).
    regexp2mi is a precompiled regexp for '-' (ie. Accept-Language: headers).
    For other header types, None leaves the value intact.
*)
val regexp3 : char option -> (char * Str.regexp) option
val regexp3sl : (char * Str.regexp) option
val regexp3mi : (char * Str.regexp) option

(** Build an element from a string.
    Can use the precompiled regexps above.
    See "type el" above.
*)
val make_el : (char * Str.regexp) option -> string -> el

(** Build an element from a supplied character.
    Note that the regexp has to be compiled.
*)
val make_el_ch : char option -> string -> el

(** The main input parser routine.
    Takes the regexp for the first element character ('/' for Accept:,
    '-' for Accept-Language:).
    Returns an abstract type with the internal representation.
*)
val make : (char * Str.regexp) option -> string -> t

(** Simple accessor function, the number of elements that have been parsed.
*)
val size : t -> int

(** Return the quality value.
    No value returns 1.0.
    If the parser found an error (eg. a malformed quality value) then
    this will be fixed at 0.0.
*)
val q_value : el -> float

(** Sort the internal list of element in decreasing quality value.
*)
val q_rank : t -> t

(** Return the n'th element from the parsed list.
    Returns None if n is out of range.
*)
val q_nth : t -> int -> el option

(** Given an element return the element in the parsed
    data which has the highest quality value.
*)
val q_max : t -> el -> float * el option

(** Given a list of elements acceptable to the server, search the
    values provided by the client for the best matching quality.
    Note that if the best matching quality is 0.0 then None is returned.
    According to the RFC, the response should be 406 Unnacceptable in this
    circumstance.
*)
val q_preferred : t -> el list -> el option

(** Return a string representation of an element.
*)
val string_of_el : string -> el -> string

(** Reconstruct a parsed string.
    Spacing may be different and the quality value may be rounded
    differently from the original.
    Otherwise, this string is suitable for embedding in Accept: headers.
*)
val to_string : t -> string

(** Same as above but returns empty string for None. *)
val to_string_opt : t option -> string

(** Find the Accept: header in a request_header and parse the string.
*)
val get_accept : request -> t option

(** Set the Accept: header line in a request.
*)
val set_accept : request -> t option -> request

(** Find the Accept-Charset: header in a request_header and parse the string.
*)
val get_accept_charset : request -> t option

(** Set the Accept-Charset: header line in a request.
*)
val set_accept_charset : request -> t option -> request

(** Find the Accept-Encoding: header in a request_header and parse the string.
*)
val get_accept_encoding : request -> t option

(** Set the Accept-Encoding: header line in a request.
*)
val set_accept_encoding : request -> t option -> request

(** Find the Accept-Language: header in a request_header and parse the string.
*)
val get_accept_language : request -> t option

(** Set the Accept-Language: header line in a request.
*)
val set_accept_language : request -> t option -> request
