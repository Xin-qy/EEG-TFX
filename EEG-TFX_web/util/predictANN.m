function [pred_class, pred_prob] = predictANN(net, x)
    x = x';
    pred_prob = net(x);
    [~, pred_class] = max(pred_prob);
    pred_class = pred_class';
end