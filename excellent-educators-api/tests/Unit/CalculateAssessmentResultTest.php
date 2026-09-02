<?php

namespace Tests\Unit;

use App\Actions\Assessments\CalculateAssessmentResult;
use App\Enums\DimensionCode;
use App\Models\AptitudeAssessmentAnswer;
use App\Models\AptitudeAssessmentOption;
use App\Models\AptitudeAssessmentOptionDimension;
use PHPUnit\Framework\TestCase;

class CalculateAssessmentResultTest extends TestCase
{
    public function test_it_counts_each_dimension_and_fills_zeros(): void
    {
        $answers = [
            $this->answer([DimensionCode::Personality]),
            $this->answer([DimensionCode::Personality]),
            $this->answer([DimensionCode::Communication]),
            $this->answer([DimensionCode::Teamwork]),
            $this->answer([DimensionCode::Personality]),
            $this->answer([DimensionCode::Creativity]),
            $this->answer([DimensionCode::Communication]),
        ];

        $scores = (new CalculateAssessmentResult)->execute($answers);

        $this->assertSame(3, $scores['P']);
        $this->assertSame(2, $scores['CM']);
        $this->assertSame(1, $scores['TW']);
        $this->assertSame(1, $scores['CR']);
        $this->assertSame(0, $scores['I']);
        $this->assertSame(0, $scores['CF']);
        $this->assertSame(0, $scores['L']);
        $this->assertSame(0, $scores['DM']);
        $this->assertSame(0, $scores['CU']);
        $this->assertSame(0, $scores['FA']);
        $this->assertCount(10, $scores);
        $this->assertSame(DimensionCode::values(), array_keys($scores));
    }

    public function test_it_counts_all_codes_on_a_multi_tagged_option(): void
    {
        $answers = [
            $this->answer([DimensionCode::Personality, DimensionCode::Creativity]),
        ];

        $scores = (new CalculateAssessmentResult)->execute($answers);

        $this->assertSame(1, $scores['P']);
        $this->assertSame(1, $scores['CR']);
        $this->assertSame(0, $scores['TW']);
    }

    /**
     * @param  list<DimensionCode>  $codes
     */
    private function answer(array $codes): AptitudeAssessmentAnswer
    {
        $option = new AptitudeAssessmentOption;
        $option->setRelation('dimensionCodes', collect($codes)->map(function (DimensionCode $code, int $index) {
            $row = new AptitudeAssessmentOptionDimension;
            $row->dimension_code = $code;
            $row->display_order = $index + 1;

            return $row;
        }));

        $answer = new AptitudeAssessmentAnswer;
        $answer->setRelation('option', $option);

        return $answer;
    }
}
