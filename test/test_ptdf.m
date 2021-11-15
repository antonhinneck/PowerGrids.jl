verbose = 1
casefile = 'case5'
mpc = loadcase(casefile);
mpopt = mpoption('out.all', 0, 'verbose', verbose);
[baseMVA, bus, gen, gencost, branch, f, success, et] = rundcopf(mpc, mpopt);
PTDF = makePTDF(baseMVA, bus, branch, 1);
LODF = makeLODF(branch, PTDF);