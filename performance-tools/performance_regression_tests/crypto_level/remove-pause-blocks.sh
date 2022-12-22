#!/bin/bash

function cleansed {
    sed -i "s/$(echo $1 | sed -e 's/\([[\/.*]\|\]\)/\\&/g')/$(echo $2 | sed -e 's/[\/&]/\\&/g')/g" $3
}

STARTTEXT="state.PauseTiming();"
ENDTEXT="state.ResumeTiming();"
LINETEXT="        for (auto _ : state)"
FILESTOEDIT=("ntt.cpp" "bfv.cpp" "ckks.cpp")
PATHTOSEAL=$(realpath $1)

if [ $# -eq 0 ]
then
    echo "please provide path to SEAL"
    exit 1
fi

for FILE in ${FILESTOEDIT[@]}; do
    FILEPATH="$PATHTOSEAL/native/bench/$FILE"
    
    while :
    do
        if grep -Fq "$STARTTEXT" $FILEPATH
        then
            # Move Block
            ed -s $FILEPATH <<__END__
/$STARTTEXT/,/$ENDTEXT/m/^$LINETEXT$/-1
wq
__END__

            # Replace Block Items
            sed -i "0,/$STARTTEXT/{s/$STARTTEXT//}" $FILEPATH
            sed -i "0,/$ENDTEXT/{s/$ENDTEXT//}" $FILEPATH
            sed -i "0,/^$LINETEXT$/{s/^$LINETEXT$/$LINETEXT \/\/edited/}" $FILEPATH
        else
            break
        fi
    done
done

# Fix Mod/ Switch Benchmarks
ORIGBFV="state.PauseTiming();
            bm_env->randomize_ct_bfv(ct[0]);

            state.ResumeTiming();
            bm_env->evaluator()->mod_switch_to_next_inplace(ct[0]);"
ORIGCKKS="state.PauseTiming();
            bm_env->randomize_ct_ckks(ct[0]);
            ct[0].scale() = scale;

            state.ResumeTiming();
            bm_env->evaluator()->rescale_to_next_inplace(ct[0])"
BFVREPLACE="bm_env->evaluator()->mod_switch_to_next_inplace(ct[0]);"
CKKSREPLACE="bm_env->evaluator()->rescale_to_next_inplace(ct[0])"

cleansed "$BFVREPLACE" "$ORIGBFV" "$PATHTOSEAL/native/bench/bfv.cpp"
cleansed "$CKKSREPLACE" "$ORIGCKKS" "$PATHTOSEAL/native/bench/ckks.cpp"
cleansed "->Unit(benchmark::kMicrosecond)" "->Unit(benchmark::kMicrosecond);//" "$PATHTOSEAL/native/bench/bench.cpp"
