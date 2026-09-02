<?php

namespace App\Actions\Content;

use App\Models\LoginPageContent;

class UpdateLoginPageContent
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function execute(array $data): LoginPageContent
    {
        $content = LoginPageContent::current();
        $content->update($data);

        return $content->fresh();
    }
}
