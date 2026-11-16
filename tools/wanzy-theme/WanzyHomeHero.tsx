import React from 'react';

const WanzyHomeHero = () => (
    <section className={'wanzy-hero'} aria-label={'Wanzy Official dashboard'}>
        <div className={'wanzy-hero-stars'} aria-hidden={'true'} />
        <div className={'wanzy-hero-copy'}>
            <div className={'wanzy-eyebrow'}>
                <span className={'wanzy-live-dot'} />
                PTERODACTYL CONTROL CENTER
            </div>
            <h1>WANZY <span>OFFICIAL</span></h1>
            <p>Manage your servers. Build without limits.</p>
            <div className={'wanzy-hero-meta'}>
                <span><i /> Secure environment</span>
                <span className={'wanzy-meta-separator'}>✦</span>
                <span>Powered by Nerxa design</span>
            </div>
        </div>
        <div className={'wanzy-orb-scene'} aria-hidden={'true'}>
            <div className={'wanzy-orbit wanzy-orbit-one'} />
            <div className={'wanzy-orbit wanzy-orbit-two'} />
            <div className={'wanzy-orbit wanzy-orbit-three'} />
            <div className={'wanzy-orb-glow'} />
            <div className={'wanzy-crystal'}>
                <div className={'wanzy-crystal-face wanzy-crystal-front'} />
                <div className={'wanzy-crystal-face wanzy-crystal-back'} />
                <div className={'wanzy-crystal-core'} />
            </div>
            <span className={'wanzy-star wanzy-star-one'}>✦</span>
            <span className={'wanzy-star wanzy-star-two'}>✧</span>
            <span className={'wanzy-star wanzy-star-three'}>✦</span>
        </div>
        <div className={'wanzy-hero-bottom'}>
            <span>WZ / 01</span>
            <span>STAY IN CONTROL <b>✦</b></span>
        </div>
    </section>
);

export default WanzyHomeHero;
