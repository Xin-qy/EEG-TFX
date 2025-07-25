function net = ANN(DATA, LABEL)
    DATA = DATA';  
    LABEL = categorical(LABEL);
    if isrow(LABEL)
        LABEL = LABEL'; 
    end
    
    LABEL_dummy = dummyvar(LABEL)'; 
   
    hiddenLayerSize = 10; 
    net = patternnet(hiddenLayerSize); 
    
    net.trainFcn = 'trainscg';  
    net.trainParam.showWindow = true;  
    net.trainParam.epochs = 1000;       
    net.trainParam.max_fail = 20;      
    
    
    net.divideParam.trainRatio = 0.7;
    net.divideParam.valRatio = 0.15;
    net.divideParam.testRatio = 0.15;

    
    [net, tr] = train(net, DATA, LABEL_dummy);
    
    
    %view(net);            
   % plotperform(tr);      
end