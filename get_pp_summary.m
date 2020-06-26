%% get pp descriptions

for exp=1:2
    if exp==1
        T = readtable('data/participants.tsv','filetype','text')
    else
        T = readtable('data_exp2/participants.tsv','filetype','text')
    end
    exp

    agemean = mean(T.age)
    agestd = std(T.age)
    agerange = [min(T.age) max(T.age)]

    nfemale = sum(strcmp(T.gender,'F'))
    nmale = sum(strcmp(T.gender,'M'))
end