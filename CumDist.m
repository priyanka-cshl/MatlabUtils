function [MyDist] = CumDist(YVar,XVar)
	MyDist = [];
	for y = 1:numel(YVar)
		for x = 1:numel(XVar)
			MyDist(x,y) = find(numel(find(YVar(:,y)<=XVar(x))));
		end
	end
end