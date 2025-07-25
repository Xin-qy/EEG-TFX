function ShEn = ShannonEntropy(X,~) 
% Convert probability using energy
P    = (X .^ 2) ./ sum(X .^ 2);
% Entropy 
En   = P .* log2(P);
ShEn = -sum(En); 
end

