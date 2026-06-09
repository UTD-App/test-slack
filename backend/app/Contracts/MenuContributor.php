<?php

namespace App\Contracts;

interface MenuContributor
{
    /** Owning package slug — must match packages.slug */
    public function getPackage(): string;

    /**
     * Default menu rows this package ships. Each `slug` MUST equal the
     * Flutter UiContribution.contributionId it maps to.
     *
     * @return array<int, array{
     *   slug:string, label_key:string, slot:string,
     *   icon?:string, active_icon?:string, route?:string, order?:int,
     *   roles?:array<string>, target?:string, parent?:string
     * }>
     */
    public function getMenuItems(): array;
}
