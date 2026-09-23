<?php

namespace App\Support;

use Illuminate\Database\Eloquent\Builder;

final class SearchRank
{
    /**
     * Rank closer matches first: exact, starts with, then other contains.
     *
     * @param  Builder<*>  $query
     * @param  list<string>  $columns
     */
    public static function orderBy(Builder $query, string $search, array $columns): void
    {
        $search = trim($search);
        if ($search === '' || $columns === []) {
            return;
        }

        $sql = 'CASE ';
        $bindings = [];
        $score = 0;

        foreach ($columns as $column) {
            $sql .= "WHEN LOWER({$column}) = LOWER(?) THEN {$score} ";
            $bindings[] = $search;
            $score++;
            $sql .= "WHEN LOWER({$column}) LIKE LOWER(?) THEN {$score} ";
            $bindings[] = $search.'%';
            $score++;
        }

        $sql .= "ELSE {$score} END";
        $query->orderByRaw($sql, $bindings);
    }
}
