function HA = HjorthActivity(X,~) 
sd = std(X); 
HA = sd ^ 2;
end