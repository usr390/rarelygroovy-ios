import { expect, $ } from '@wdio/globals'

describe('Rarelygroovy app', () => {
  it('should open home screen', async () => {
    const homeTitle = await $('~calendar') // using accessibility id
    await expect(homeTitle).toBeDisplayed()
  })
    it('should load events', async () => {
    const eventsListedLabel = await $('~eventsListedLabel') // using accessibility id
    await expect(eventsListedLabel).toBeDisplayed()
  })
    it('should navigate to the Artist Directory and load', async () => {
        const artistDirectoryBtn = await $('~Artist Directory');
        await artistDirectoryBtn.click();

        const firstBandName = await $('~. . . And The Hero Prevails') // using accessibility id
        await expect(firstBandName).toBeDisplayed()
  })
})


