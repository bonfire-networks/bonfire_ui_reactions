import 'emoji-picker-element';

const ReactionPicker = {
  mounted() {
    // const button = this.el.querySelector('.reaction-button');
    const picker = this.el.querySelector('emoji-picker');
    const objectId = this.el.dataset.objectId;

    const pickerContainer = document.querySelector('#emoji-picker-in-composer');

    let customEmoji = [];
    if (pickerContainer) {
      try {
        const emojisData = pickerContainer.getAttribute('data-emojis');
        if (emojisData) {
          customEmoji = JSON.parse(emojisData);
        }
      } catch (e) {
        console.error('Failed to parse custom emojis:', e);
      }
    }

    picker.customEmoji = customEmoji;

    picker.addEventListener('emoji-click', event => {
      // console.log(event.detail)
      // Send the reaction to the server
      this.pushEventTo(this.el, "Bonfire.Social.Likes:add_reaction", {
        emoji: event.detail.unicode || event.detail.emoji.shortcodes,
        emoji_id: event.detail.emoji.id,
        id: objectId,
        label: event.detail.emoji.annotation
      });

    });
  }
};

export default ReactionPicker;