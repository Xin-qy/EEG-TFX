function MCL = MeanCurveLength(X,~)
N = length(X); 
Y = 0;
for m = 2:N
  Y = Y + abs(X(m) - X(m-1));
end
MCL = (1 / N) * Y;
end

