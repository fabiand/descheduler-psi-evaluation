handle() {
  TAINT="kubevirt.io/rebalance:PreferNoSchedule"
  oc_taint="echo oc adm taint node"
  tr -d '"' | while read LINE; do
    if grep -qE "descheduler.*Number of evictions.*" <<<$LINE
    then $oc_taint --all ${TAINT}- ; fi
    if grep -qE "nodeutilization.*Node is overutilized.*" <<<$LINE
    then NODE=$(echo "$LINE" | grep -E -o "node=[^ ]+" | cut -d= -f2-) ;  $oc_taint $NODE ${TAINT} ; fi
  done
}


verify() {
  testdata() { cat <<EOF
  I1209 11:33:20.308217       1 descheduler.go:354] "Number of evictions/requests" totalEvicted=0 evictionRequests=0
  I1209 11:33:32.294373       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-master-0"
  I1209 11:33:32.294450       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-master-1"
  I1209 11:33:32.294478       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-master-2"
  I1209 11:33:32.294518       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus1-d9xt5"
  I1209 11:33:32.294551       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus2-xwfw7"
  I1209 11:33:32.294582       1 toomanyrestarts.go:116] "Processing node" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus3-tdzxf"
  I1209 11:33:32.294609       1 profile.go:347] "Total number of evictions/requests" extension point="Deschedule" evictedPods=0 evictionRequests=0
  I1209 11:33:32.297747       1 nodeutilization.go:208] "Node is appropriately utilized" node="ci-ln-gi479l2-1d09d-g4n22-master-0" usage={"MetricResource":"45"} usagePercentage={"MetricResource":45}
  I1209 11:33:32.297777       1 nodeutilization.go:208] "Node is appropriately utilized" node="ci-ln-gi479l2-1d09d-g4n22-master-1" usage={"MetricResource":"45"} usagePercentage={"MetricResource":45}
  I1209 11:33:32.297785       1 nodeutilization.go:208] "Node is appropriately utilized" node="ci-ln-gi479l2-1d09d-g4n22-master-2" usage={"MetricResource":"38"} usagePercentage={"MetricResource":38}
  I1209 11:33:32.297792       1 nodeutilization.go:205] "Node is overutilized" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus1-d9xt5" usage={"MetricResource":"54"} usagePercentage={"MetricResource":54}
  I1209 11:33:32.297799       1 nodeutilization.go:205] "Node is overutilized" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus2-xwfw7" usage={"MetricResource":"62"} usagePercentage={"MetricResource":62}
  I1209 11:33:32.297806       1 nodeutilization.go:205] "Node is overutilized" node="ci-ln-gi479l2-1d09d-g4n22-worker-centralus3-tdzxf" usage={"MetricResource":"56"} usagePercentage={"MetricResource":56}
  I1209 11:33:32.297812       1 lownodeutilization.go:159] "Criteria for a node under utilization" CPU=0 Mem=0 Pods=0 MetricResource=20
  I1209 11:33:32.297819       1 lownodeutilization.go:160] "Number of underutilized nodes" totalNumber=0
  I1209 11:33:32.297825       1 lownodeutilization.go:163] "Criteria for a node above target utilization" CPU=0 Mem=0 Pods=0 MetricResource=50
  I1209 11:33:32.297831       1 lownodeutilization.go:164] "Number of overutilized nodes" totalNumber=3
  I1209 11:33:32.297837       1 lownodeutilization.go:167] "No node is underutilized, nothing to do here, you might tune your thresholds further"
  I1209 11:33:32.297852       1 profile.go:376] "Total number of evictions/requests" extension point="Balance" evictedPods=0 evictionRequests=0
  I1209 11:33:32.297867       1 descheduler.go:354] "Number of evictions/requests" totalEvicted=0 evictionRequests=0
EOF
  }

  EXPECTED="oc adm taint node --all kubevirt.io/rebalance:PreferNoSchedule-
oc adm taint node ci-ln-gi479l2-1d09d-g4n22-worker-centralus1-d9xt5 kubevirt.io/rebalance:PreferNoSchedule
oc adm taint node ci-ln-gi479l2-1d09d-g4n22-worker-centralus2-xwfw7 kubevirt.io/rebalance:PreferNoSchedule
oc adm taint node ci-ln-gi479l2-1d09d-g4n22-worker-centralus3-tdzxf kubevirt.io/rebalance:PreferNoSchedule
oc adm taint node --all kubevirt.io/rebalance:PreferNoSchedule-"

  [[ "$EXPECTED" == "$(testdata | handle)" ]] && echo PASS || { echo FAIL ; echo -e "$EXPECTED" ; echo -e "$STDOUT" ; }
}

${@:-handle}