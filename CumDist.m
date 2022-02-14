function [MyDist] = CumDist(YVar,XVar)
	MyDist = [];
	for y = 1:size(YVar,2)
		for x = 1:numel(XVar)-1
			MyDist(x,y) = numel(find(YVar(:,y)<=XVar(x)));
        end 
        x = x+1;
        MyDist(x,y) = MyDist(x-1,y) + numel(find(YVar(:,y)>XVar(x)));
        MyDist(:,y) = MyDist(:,y)/max(MyDist(:,y));
	end
end