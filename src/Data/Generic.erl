-module(data_generic@foreign).
-export([zipAll/3, zipCompare/3]).

zipAll(F,Xs,Ys) ->
  XsL = array:to_list(Xs),
  YsL = array:to_list(Ys),
  L = min(length(XsL), length(YsL)),
  List = lists:zip(lists:sublist(XsL, L), lists:sublist(YsL, L)),
  lists:all(fun ({X, Y}) -> (F(X))(Y) end, List).

zipCompare(F,Xs,Ys) ->
  XsL = array:to_list(Xs),
  YsL = array:to_list(Ys),
  L1 = length(XsL),
  L2 = length(YsL),
  L = min(L1, L2),
  List = lists:zip(lists:sublist(XsL, L), lists:sublist(YsL, L)),
  case lists:filter(fun ({X, Y}) -> (F(X))(Y) =/= 0 end, List) of
    [N|_] -> N;
    _ when L1 =:= L2 -> 0;
    _ when L1 > L2 -> -1;
    _ when L1 < L2 -> 1
  end.
