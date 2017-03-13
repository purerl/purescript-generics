-module(data_generic@foreign).
-export([zipAll/3, zipCompare/3]).

zipAll(F,Xs,Ys) =
  XsL = array:from_list(Xs),
  YsL = array:from_list(Ys),
  L = min(lists:length(XsL), lists:length(YsL)),
  List = zip(lists:sublist(XsL, L), lists:sublist(YsL, L)),
  lists:all(fun (X, Y) -> (F(X))(Y), List).

zipCompare(F,Xs,Ys) =
  XsL = array:from_list(Xs),
  YsL = array:from_list(Ys),
  L1 = lists:length(XsL),
  L2 = lists:length(YsL),
  L = min(L1, L2),
  List = zip(lists:sublist(XsL, L), lists:sublist(YsL, L)),
  case lists:filter(fun (X, Y) -> (F(X))(Y) =/= 0, List) of
    [N|_] -> N
    _ when L1 =:= L2 -> 0
    _ when L1 > L2 -> -1
    _ when L1 < L2 -> 1
  end.
