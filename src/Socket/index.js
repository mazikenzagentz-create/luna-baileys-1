import chalk from 'chalk';
import { DEFAULT_CONNECTION_CONFIG } from '../Defaults/index.js';
import { prepareModernMessageContent } from '../Utils/modern-messages.js';
import { makeNewsletterStatusFetcher, makeNewsletterStatusUpdatesFetcher, makeNewsletterStatusReactionSender, makeNewsletterStatusRevokeSender, makeNewsletterStatusSender } from '../Utils/newsletter-status.js';
import { bindVoiceRecognition } from '../Utils/voice-recognition.js';
import { makeCommunitiesSocket } from './communities.js';
import { makeEmailCoordinator } from './email.js';
import { makeMobileCoordinator } from './mobile.js';


let arrivalShown = false;

const showArrivalBanner = () => {
    if (arrivalShown) return;
    arrivalShown = true;

    const printBanner = () => {
        console.log(chalk.cyanBright('╔══════════════════════════════════════╗'));
        console.log(chalk.cyanBright('║') + chalk.yellowBright.bold('            M A R C H E L             ') + chalk.cyanBright('║'));
        console.log(chalk.cyanBright('║') + chalk.yellowBright.bold('              T E C H                 ') + chalk.cyanBright('║'));
        console.log(chalk.cyanBright('╚══════════════════════════════════════╝'));
        console.log(chalk.blueBright('  ⎻͞⎼⎽͞᚜𒁂 WhatsApp Api ready 𒁂᚜⎽͞⎼⎻͞'));
        console.log(chalk.gray('  ────────────────────────────────────'));
        console.log(chalk.magentaBright('  Thankyou for using this baileys'));
        console.log(chalk.redBright('  Developer  : ') + chalk.whiteBright('Marchel Tech'));
        console.log(chalk.greenBright('  Contact    : ') + chalk.whiteBright('+44 7536 649895'));
        console.log(chalk.gray('────────────────────────────────────────\\n'));
    };

    if (!process.stdout?.isTTY) {
        printBanner();
        return;
    }

    const frames = ['[          ]', '[██        ]', '[████      ]', '[██████    ]', '[████████  ]', '[██████████]'];
    let frame = 0;
    const timer = setInterval(() => {
        process.stdout.write('\\r' + chalk.cyanBright('  Initializing Marchel Tech ' + frames[frame]));
        frame += 1;
        if (frame >= frames.length) {
            clearInterval(timer);
            process.stdout.write('\\n');
            printBanner();
        }
    }, 90);
};

const makeWASocket = (config) => {
    showArrivalBanner();
    const newConfig = {
        ...DEFAULT_CONNECTION_CONFIG,
        ...config
    };
    const sock = makeCommunitiesSocket(newConfig);
    const isMobilePrimary = () => (typeof newConfig.isMobilePrimary === 'function' ? newConfig.isMobilePrimary() : !!newConfig.mobileTransport?.deviceInfo || !!newConfig.deviceInfo || !!newConfig.mobile);
    sock.email = makeEmailCoordinator(sock.query, isMobilePrimary);
    sock.mobile = makeMobileCoordinator(sock, newConfig);
    bindVoiceRecognition(sock, newConfig);
    const sendMessage = sock.sendMessage.bind(sock);
    sock.sendMessage = (jid, content, options = {}) => sendMessage(jid, prepareModernMessageContent(content), options);
    sock.sendNewsletterStatus = makeNewsletterStatusSender(sock, newConfig);
    sock.sendNewsletterStatusReaction = makeNewsletterStatusReactionSender(sock);
    sock.revokeNewsletterStatus = makeNewsletterStatusRevokeSender(sock);
    sock.getNewsletterStatuses = makeNewsletterStatusFetcher(sock);
    sock.getNewsletterStatusUpdates = makeNewsletterStatusUpdatesFetcher(sock);
    if (newConfig.AnchorGuard) {
        import('@rexxhayanasi/elaina-anchorguard')
            .then(({ createAntiBugGuard }) => {
                sock.anchorGuard = createAntiBugGuard(sock, { logger: sock.logger, ...(newConfig.AnchorGuardConfig || {}) });
            })
            .catch((error) => {
                sock.logger?.warn?.({ error: error.message }, 'AnchorGuard diaktifkan tapi paket @rexxhayanasi/elaina-anchorguard belum terpasang. Jalankan: npm install @rexxhayanasi/elaina-anchorguard');
            });
    }
    return sock;
};
export default makeWASocket;
